import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Ventana sin barra de título separada e integrada con los controles de SILM
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    self.isMovableByWindowBackground = true
    self.standardWindowButton(.closeButton)?.isHidden = true
    self.standardWindowButton(.miniaturizeButton)?.isHidden = true
    self.standardWindowButton(.zoomButton)?.isHidden = true

    let windowChannel = FlutterMethodChannel(
      name: "silm/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    windowChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      switch call.method {
      case "minimize":
        self.miniaturize(nil)
        result(nil)
      case "maximize":
        self.zoom(nil)
        result(nil)
      case "close":
        self.performClose(nil)
        result(nil)
      case "startDrag":
        if let event = NSApp.currentEvent {
          self.performDrag(with: event)
        }
        result(nil)
      case "isMaximized":
        result(self.isZoomed)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
