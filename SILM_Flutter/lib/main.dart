import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SILMApp());
}

class SILMApp extends StatefulWidget {
  const SILMApp({super.key});

  @override
  State<SILMApp> createState() => _SILMAppState();
}

class _SILMAppState extends State<SILMApp> {
  bool _authenticated = false;
  bool _isDarkMode = true;
  double _zoomFactor = 1.0;
  bool _showZoomBadge = false;
  Timer? _zoomBadgeTimer;

  static const double _minZoom = 0.7;
  static const double _maxZoom = 1.6;
  static const double _zoomStep = 0.1;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _zoomBadgeTimer?.cancel();
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }

    final kb = HardwareKeyboard.instance;
    final hasPrimaryModifier = kb.isControlPressed || kb.isMetaPressed;
    if (!hasPrimaryModifier || kb.isAltPressed) {
      return false;
    }

    final key = event.logicalKey;
    final char = event.character;

    final isZoomIn = key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd ||
        key == LogicalKeyboardKey.equal ||
        char == '+';

    final isZoomOut = key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract ||
        char == '-';

    final isZoomReset =
        key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0;

    if (isZoomIn) {
      _updateZoom((_zoomFactor + _zoomStep).clamp(_minZoom, _maxZoom));
      return true;
    }
    if (isZoomOut) {
      _updateZoom((_zoomFactor - _zoomStep).clamp(_minZoom, _maxZoom));
      return true;
    }
    if (isZoomReset) {
      _updateZoom(1.0);
      return true;
    }

    return false;
  }

  void _updateZoom(double next) {
    // Evitar imprecisiones de punto flotante (ej. 1.1000000000000001)
    final rounded = (next * 10).round() / 10.0;
    setState(() {
      _zoomFactor = rounded;
      _showZoomBadge = true;
    });
    _zoomBadgeTimer?.cancel();
    _zoomBadgeTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _showZoomBadge = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SILM',
      theme: voxelTheme(),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        Widget content = child;
        if ((_zoomFactor - 1.0).abs() >= 0.001) {
          final mq = MediaQuery.of(context);
          final logicalSize = mq.size / _zoomFactor;
          content = Align(
            alignment: Alignment.topLeft,
            child: Transform.scale(
              scale: _zoomFactor,
              alignment: Alignment.topLeft,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: logicalSize.width,
                maxWidth: logicalSize.width,
                minHeight: logicalSize.height,
                maxHeight: logicalSize.height,
                child: MediaQuery(
                  data: mq.copyWith(
                    size: logicalSize,
                    padding: mq.padding / _zoomFactor,
                    viewPadding: mq.viewPadding / _zoomFactor,
                    viewInsets: mq.viewInsets / _zoomFactor,
                  ),
                  child: child,
                ),
              ),
            ),
          );
        }

        return WindowResizeOverlay(
          child: Stack(
            children: [
              content,
              if (_showZoomBadge)
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: IgnorePointer(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181A20).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _zoomFactor > 1.0
                                  ? Icons.zoom_in_rounded
                                  : (_zoomFactor < 1.0
                                      ? Icons.zoom_out_rounded
                                      : Icons.center_focus_strong_rounded),
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Zoom ${(_zoomFactor * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      home: _authenticated
          ? HomeScreen(
              isDarkMode: _isDarkMode,
              onThemeModeChanged: (isDarkMode) {
                setState(() => _isDarkMode = isDarkMode);
                setVoxelDarkMode(isDarkMode);
              },
              onLogout: () => setState(() => _authenticated = false),
            )
          : LoginScreen(
              onLoginSuccess: () => setState(() => _authenticated = true)),
    );
  }
}

typedef VoxelcostApp = SILMApp;

