#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "silm/window",
          &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler(
      [hwnd = GetHandle()](
          const flutter::MethodCall<flutter::EncodableValue>& call,
          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
              result) {
        if (call.method_name() == "minimize") {
          ShowWindow(hwnd, SW_MINIMIZE);
          result->Success();
        } else if (call.method_name() == "maximize") {
          ShowWindow(hwnd, IsZoomed(hwnd) ? SW_RESTORE : SW_MAXIMIZE);
          result->Success();
        } else if (call.method_name() == "close") {
          PostMessage(hwnd, WM_CLOSE, 0, 0);
          result->Success();
        } else if (call.method_name() == "startDrag") {
          ReleaseCapture();
          SendMessage(hwnd, WM_NCLBUTTONDOWN, HTCAPTION, 0);
          result->Success();
        } else if (call.method_name() == "startResize") {
          std::string edge = "bottomRight";
          if (call.arguments() &&
              std::holds_alternative<std::string>(*call.arguments())) {
            edge = std::get<std::string>(*call.arguments());
          }
          WPARAM hit_test = HTBOTTOMRIGHT;
          if (edge == "topLeft") {
            hit_test = HTTOPLEFT;
          } else if (edge == "top") {
            hit_test = HTTOP;
          } else if (edge == "topRight") {
            hit_test = HTTOPRIGHT;
          } else if (edge == "left") {
            hit_test = HTLEFT;
          } else if (edge == "right") {
            hit_test = HTRIGHT;
          } else if (edge == "bottomLeft") {
            hit_test = HTBOTTOMLEFT;
          } else if (edge == "bottom") {
            hit_test = HTBOTTOM;
          }
          ReleaseCapture();
          SendMessage(hwnd, WM_NCLBUTTONDOWN, hit_test, 0);
          result->Success();
        } else if (call.method_name() == "isMaximized") {
          result->Success(
              flutter::EncodableValue(static_cast<bool>(IsZoomed(hwnd))));
        } else {
          result->NotImplemented();
        }
      });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  SetWindowPos(GetHandle(), nullptr, 0, 0, 0, 0,
               SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER);
  Show();

  flutter_controller_->engine()->SetNextFrameCallback([this]() {
    Show();
  });

  // Request the first frame after the window and Flutter view are connected.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_NCCALCSIZE: {
      if (wparam == TRUE) {
        NCCALCSIZE_PARAMS* params =
            reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam);
        if (IsZoomed(hwnd)) {
          HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
          MONITORINFO mi = {sizeof(mi)};
          if (GetMonitorInfo(monitor, &mi)) {
            params->rgrc[0] = mi.rcWork;
          }
        }
        return 0;
      }
      break;
    }
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
