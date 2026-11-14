import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;

bool _isDarkMode = true;

void setVoxelDarkMode(bool enabled) => _isDarkMode = enabled;
bool get isVoxelDarkMode => _isDarkMode;

// --- PALETA ANTIGRAVITY / JET BLACK (NEGRO PURO, CERO AZULADO) ---
Color get bgBase =>
    _isDarkMode ? const Color(0xFF0C0D0E) : const Color(0xFFF6F8FA);
Color get surfaceCard =>
    _isDarkMode ? const Color(0xFF141416) : const Color(0xFFFFFFFF);
Color get surfaceElevated =>
    _isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFFF1F5F9);
Color get borderSubtle =>
    _isDarkMode ? const Color(0xFF26262B) : const Color(0xFFE2E8F0);
Color get borderStrong =>
    _isDarkMode ? const Color(0xFF3A3A42) : const Color(0xFFCBD5E1);
Color get textPrimary =>
    _isDarkMode ? const Color(0xFFF4F4F5) : const Color(0xFF0F172A);
Color get textSecondary =>
    _isDarkMode ? const Color(0xFFA1A1AA) : const Color(0xFF475569);
Color get textMuted =>
    _isDarkMode ? const Color(0xFF71717A) : const Color(0xFF94A3B8);

// Acentos modernos (Electric Apple / Linear Blue)
const accentPetrol = Color(0xFF2563EB);
const accentPetrolHover = Color(0xFF1D4ED8);
const accentPetrolPressed = Color(0xFF1E40AF);
const accentAmber = Color(0xFF0284C7);

// Semánticos vivos y armónicos
const semanticSuccess = Color(0xFF10B981);
const semanticWarning = Color(0xFFF59E0B);
const semanticDanger = Color(0xFFEF4444);

// Gráficas de Producción
const chartPrimary = Color(0xFF2563EB);
const chartPrimaryLight = Color(0xFF60A5FA);
Color get chartSecondary => textPrimary;
Color get chartAux => textSecondary;

// --- PALETA CENTRALIZADA DE COLORES (FILAMENTOS 3D) ---
class VoxelColor {
  final String name;
  final String hex;
  final int value;
  final bool isTransparent;

  const VoxelColor({
    required this.name,
    required this.hex,
    required this.value,
    this.isTransparent = false,
  });

  Color get color => Color(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoxelColor &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          name.toLowerCase() == other.name.toLowerCase();

  @override
  int get hashCode => Object.hash(name.toLowerCase(), value);
}

const List<VoxelColor> voxelColorPalette = [
  VoxelColor(name: 'Blanco', hex: '#FFFFFF', value: 0xFFFFFFFF),
  VoxelColor(name: 'Negro', hex: '#111111', value: 0xFF111111),
  VoxelColor(name: 'Gris', hex: '#808080', value: 0xFF808080),
  VoxelColor(name: 'Silver', hex: '#C0C0C0', value: 0xFFC0C0C0),
  VoxelColor(name: 'Rojo', hex: '#E53935', value: 0xFFE53935),
  VoxelColor(name: 'Naranja', hex: '#FB8C00', value: 0xFFFB8C00),
  VoxelColor(name: 'Amarillo', hex: '#FDD835', value: 0xFFFDD835),
  VoxelColor(name: 'Verde', hex: '#43A047', value: 0xFF43A047),
  VoxelColor(name: 'Verde lima', hex: '#C0CA33', value: 0xFFC0CA33),
  VoxelColor(name: 'Azul', hex: '#1E88E5', value: 0xFF1E88E5),
  VoxelColor(name: 'Azul marino', hex: '#1A237E', value: 0xFF1A237E),
  VoxelColor(name: 'Celeste', hex: '#4FC3F7', value: 0xFF4FC3F7),
  VoxelColor(name: 'Petrol', hex: '#2E8B98', value: 0xFF2E8B98),
  VoxelColor(name: 'Morado', hex: '#8E24AA', value: 0xFF8E24AA),
  VoxelColor(name: 'Rosa', hex: '#EC407A', value: 0xFFEC407A),
  VoxelColor(name: 'Café', hex: '#6D4C41', value: 0xFF6D4C41),
  VoxelColor(name: 'Beige', hex: '#D7C4A3', value: 0xFFD7C4A3),
  VoxelColor(name: 'Oro', hex: '#D4AF37', value: 0xFFD4AF37),
  VoxelColor(
      name: 'Transparente',
      hex: '#00000000',
      value: 0x00000000,
      isTransparent: true),
];

VoxelColor findVoxelColor({int? value, String? name, String? hex}) {
  if (value != null) {
    for (final c in voxelColorPalette) {
      if (c.value == value) return c;
    }
  }
  if (name != null && name.trim().isNotEmpty) {
    for (final c in voxelColorPalette) {
      if (c.name.toLowerCase() == name.trim().toLowerCase()) return c;
    }
  }
  if (hex != null && hex.trim().isNotEmpty) {
    final clean = hex.replaceAll('#', '').toUpperCase();
    for (final c in voxelColorPalette) {
      if (c.hex.replaceAll('#', '').toUpperCase() == clean) return c;
    }
  }
  if (hex != null && hex.trim().isNotEmpty) {
    final parsed = parseHex(hex);
    return VoxelColor(
      name: name ?? hex,
      hex: hex.startsWith('#') ? hex : '#$hex',
      value: parsed.toARGB32(),
    );
  }
  if (value != null) {
    final hexStr =
        '#${value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    return VoxelColor(name: name ?? 'Color', hex: hexStr, value: value);
  }
  return voxelColorPalette[0];
}

// Compatibilidad retroactiva
Color get darkBackground => bgBase;
const techCyan = accentPetrol;
const techPrimaryDark = accentPetrolPressed;
Color get cardWhite => surfaceCard;
Color get textBlack => textPrimary;
Color get inputGray => surfaceElevated;
Color get iconGray => textSecondary;
const errorRed = semanticDanger;
Color get machineGray => borderStrong;
const iridescentPink = chartPrimaryLight;
const iridescentPurple = accentPetrol;
Color get surfaceSoft => surfaceElevated;

ThemeData voxelTheme() => ThemeData(
      useMaterial3: true,
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bgBase,
      canvasColor: surfaceCard,
      colorScheme: ColorScheme(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        primary: accentPetrol,
        onPrimary: const Color(0xFFFFFFFF),
        secondary: accentAmber,
        onSecondary: const Color(0xFFFFFFFF),
        surface: surfaceCard,
        onSurface: textPrimary,
        error: semanticDanger,
        onError: const Color(0xFFFFFFFF),
        onSurfaceVariant: textSecondary,
        surfaceContainerHighest: surfaceElevated,
        outline: _isDarkMode ? const Color(0xFF3A3A42) : const Color(0xFFE2E8F0),
        outlineVariant: _isDarkMode ? const Color(0xFF222226) : const Color(0xFFF1F5F9),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          fontFamilyFallback: const ['Inter', 'sans-serif'],
        ),
      ),
      dividerTheme: DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderSubtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: TextStyle(color: textMuted, fontSize: 13),
        labelStyle: TextStyle(color: textSecondary, fontSize: 13),
        floatingLabelStyle: const TextStyle(
          color: accentPetrol,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentPetrol, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: semanticDanger),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: accentPetrol,
        selectionColor: Color(0x442E8B96),
        selectionHandleColor: accentPetrol,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: 1.0,
          color: textPrimary,
          fontFamilyFallback: const ['Inter', 'sans-serif'],
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 0.8,
          color: textPrimary,
          fontFamilyFallback: const ['Inter', 'sans-serif'],
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: 0.3,
          color: textPrimary,
          fontFamilyFallback: const ['Inter', 'sans-serif'],
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.2,
          color: textPrimary,
          fontFamilyFallback: const ['Inter', 'sans-serif'],
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 13,
          color: textSecondary,
          fontFamilyFallback: const ['Inter', 'sans-serif'],
        ),
        labelSmall: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 1.0,
          color: textSecondary,
          fontFamilyFallback: const ['Inter', 'sans-serif'],
        ),
      ),
    );

InputDecoration fieldDecoration(
  String label, {
  String? hint,
  Widget? prefix,
  Widget? suffix,
}) =>
    InputDecoration(
      labelText: label.isEmpty ? null : label,
      hintText: hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: surfaceElevated,
      labelStyle: TextStyle(
        color: textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: accentPetrol,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(color: textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentPetrol, width: 1.5),
      ),
    );

Widget formCard({
  required String title,
  required Widget child,
  String? subtitle,
  Widget? trailing,
}) =>
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : borderSubtle,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.35 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );

class SidebarToggleIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const SidebarToggleIcon({
    super.key,
    this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SidebarIconPainter(color: color ?? textPrimary),
    );
  }
}

class _SidebarIconPainter extends CustomPainter {
  final Color color;

  _SidebarIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.09;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rectWidth = size.width - strokeWidth * 2;
    final rectHeight = size.height * 0.82;
    final left = strokeWidth;
    final top = (size.height - rectHeight) / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, rectWidth, rectHeight),
      Radius.circular(size.width * 0.18),
    );

    canvas.drawRRect(rrect, paint);

    // Divisor vertical izquierdo
    final dividerX = left + rectWidth * 0.33;
    canvas.drawLine(
      Offset(dividerX, top),
      Offset(dividerX, top + rectHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SidebarIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

String cleanAppBarTitle(String raw) {
  if (raw.isEmpty) return raw;
  final parts = raw.split(' ');
  return parts.map((w) {
    if (w.isEmpty) return w;
    final upper = w.toUpperCase();
    if (upper == 'DE' || upper == 'DEL' || upper == 'Y' || upper == 'EN') {
      return w.toLowerCase();
    }
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }).join(' ');
}

enum WindowResizeEdge {
  topLeft,
  top,
  topRight,
  left,
  right,
  bottomLeft,
  bottom,
  bottomRight,
}

class SilmWindowControls {
  static const MethodChannel _channel = MethodChannel('silm/window');

  static bool get isCustomFrameSupported =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  static bool get isCustomResizeSupported =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows);

  static Future<void> minimize() async {
    if (!isCustomFrameSupported) return;
    try {
      await _channel.invokeMethod('minimize');
    } catch (_) {}
  }

  static Future<void> toggleMaximize() async {
    if (!isCustomFrameSupported) return;
    try {
      await _channel.invokeMethod('maximize');
    } catch (_) {}
  }

  static Future<void> close() async {
    if (!isCustomFrameSupported) return;
    try {
      await _channel.invokeMethod('close');
    } catch (_) {}
  }

  static Future<void> startDrag() async {
    if (!isCustomFrameSupported) return;
    try {
      await _channel.invokeMethod('startDrag');
    } catch (_) {}
  }

  static Future<void> startResize(WindowResizeEdge edge) async {
    if (!isCustomResizeSupported) return;
    try {
      await _channel.invokeMethod('startResize', edge.name);
    } catch (_) {}
  }
}

class WindowResizeOverlay extends StatelessWidget {
  final Widget child;
  const WindowResizeOverlay({super.key, required this.child});

  static const double _edgeThickness = 6.0;
  static const double _cornerSize = 12.0;

  Widget _buildHandle(WindowResizeEdge edge, MouseCursor cursor) {
    return MouseRegion(
      cursor: cursor,
      opaque: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => SilmWindowControls.startResize(edge),
        child: const SizedBox.expand(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!SilmWindowControls.isCustomResizeSupported) return child;
    return Stack(
      children: [
        child,
        // Bordes laterales y superior/inferior
        Positioned(
          top: 0,
          left: _cornerSize,
          right: _cornerSize,
          height: _edgeThickness,
          child: _buildHandle(
            WindowResizeEdge.top,
            SystemMouseCursors.resizeUpDown,
          ),
        ),
        Positioned(
          bottom: 0,
          left: _cornerSize,
          right: _cornerSize,
          height: _edgeThickness,
          child: _buildHandle(
            WindowResizeEdge.bottom,
            SystemMouseCursors.resizeUpDown,
          ),
        ),
        Positioned(
          left: 0,
          top: _cornerSize,
          bottom: _cornerSize,
          width: _edgeThickness,
          child: _buildHandle(
            WindowResizeEdge.left,
            SystemMouseCursors.resizeLeftRight,
          ),
        ),
        Positioned(
          right: 0,
          top: _cornerSize,
          bottom: _cornerSize,
          width: _edgeThickness,
          child: _buildHandle(
            WindowResizeEdge.right,
            SystemMouseCursors.resizeLeftRight,
          ),
        ),
        // Esquinas
        Positioned(
          top: 0,
          left: 0,
          width: _cornerSize,
          height: _cornerSize,
          child: _buildHandle(
            WindowResizeEdge.topLeft,
            SystemMouseCursors.resizeUpLeftDownRight,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          width: _cornerSize,
          height: _cornerSize,
          child: _buildHandle(
            WindowResizeEdge.topRight,
            SystemMouseCursors.resizeUpRightDownLeft,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          width: _cornerSize,
          height: _cornerSize,
          child: _buildHandle(
            WindowResizeEdge.bottomLeft,
            SystemMouseCursors.resizeUpRightDownLeft,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          width: _cornerSize,
          height: _cornerSize,
          child: _buildHandle(
            WindowResizeEdge.bottomRight,
            SystemMouseCursors.resizeUpLeftDownRight,
          ),
        ),
      ],
    );
  }
}

class WindowDragArea extends StatelessWidget {
  final Widget child;
  const WindowDragArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!SilmWindowControls.isCustomFrameSupported) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => SilmWindowControls.startDrag(),
      onDoubleTap: SilmWindowControls.toggleMaximize,
      child: child,
    );
  }
}

class WindowCaptionButtons extends StatelessWidget {
  final Color? iconColor;

  const WindowCaptionButtons({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    if (!SilmWindowControls.isCustomFrameSupported) {
      return const SizedBox.shrink();
    }
    final fg = iconColor ?? textSecondary;
    final subtleHover = _isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowCaptionButton(
          tooltip: 'Minimizar',
          icon: Icons.remove_rounded,
          color: fg,
          hoverBg: subtleHover,
          onTap: SilmWindowControls.minimize,
        ),
        const SizedBox(width: 2),
        _WindowCaptionButton(
          tooltip: 'Maximizar / Restaurar',
          icon: Icons.crop_square_rounded,
          iconSize: 14,
          color: fg,
          hoverBg: subtleHover,
          onTap: SilmWindowControls.toggleMaximize,
        ),
        const SizedBox(width: 2),
        _WindowCaptionButton(
          tooltip: 'Cerrar',
          icon: Icons.close_rounded,
          color: fg,
          hoverColor: Colors.white,
          hoverBg: const Color(0xFFE53935),
          onTap: SilmWindowControls.close,
        ),
      ],
    );
  }
}

class _WindowCaptionButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final double iconSize;
  final Color color;
  final Color? hoverColor;
  final Color hoverBg;
  final VoidCallback onTap;

  const _WindowCaptionButton({
    required this.tooltip,
    required this.icon,
    this.iconSize = 16,
    required this.color,
    this.hoverColor,
    required this.hoverBg,
    required this.onTap,
  });

  @override
  State<_WindowCaptionButton> createState() => _WindowCaptionButtonState();
}

class _WindowCaptionButtonState extends State<_WindowCaptionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 30,
            height: 28,
            decoration: BoxDecoration(
              color: _hover ? widget.hoverBg : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: _hover ? (widget.hoverColor ?? widget.color) : widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

PreferredSizeWidget darkAppBar(
  String title,
  VoidCallback onBack, {
  String? subtitle,
  List<Widget> actions = const [],
  IconData leadingIcon = Icons.arrow_back,
  Widget? leadingWidget,
  String? leadingTooltip,
  VoidCallback? onHoverEnter,
  VoidCallback? onHoverExit,
  bool hideLeading = false,
}) =>
    AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: subtitle != null ? 76 : 68,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: hideLeading ? 24 : 8,
      leadingWidth: hideLeading ? 0 : 52,
      flexibleSpace: SilmWindowControls.isCustomFrameSupported
          ? const WindowDragArea(child: SizedBox.expand())
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cleanAppBarTitle(title),
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              fontSize: 24,
              fontFamilyFallback: const ['Inter', 'sans-serif'],
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                fontFamilyFallback: const ['Inter', 'sans-serif'],
              ),
            ),
          ],
        ],
      ),
      leading: hideLeading
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 12),
              child: MouseRegion(
                onEnter: onHoverEnter != null ? (_) => onHoverEnter() : null,
                onExit: onHoverExit != null ? (_) => onHoverExit() : null,
                child: IconButton(
                  hoverColor: surfaceElevated,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  tooltip: leadingTooltip,
                  mouseCursor: SystemMouseCursors.click,
                  onPressed: onBack,
                  icon: leadingWidget ??
                      Icon(leadingIcon, color: textPrimary, size: 20),
                ),
              ),
            ),
      actions: [
        ...actions,
        if (SilmWindowControls.isCustomFrameSupported) ...[
          if (actions.isNotEmpty) const SizedBox(width: 8),
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 10),
              child: WindowCaptionButtons(),
            ),
          ),
        ],
        const SizedBox(width: 12),
      ],
    );

Color parseHex(String hex) {
  final value = hex.replaceFirst('#', '');
  return Color(int.parse(value.length == 6 ? 'FF$value' : value, radix: 16));
}

class SilmDropdownOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool dividerBefore;

  const SilmDropdownOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.dividerBefore = false,
  });
}

class SilmPopupDropdown<T> extends StatelessWidget {
  final T value;
  final List<SilmDropdownOption<T>> options;
  final ValueChanged<T> onSelected;
  final String? prefixLabel;
  final IconData? leadingIcon;
  final String? tooltip;
  final bool highlightWhenNotDefault;
  final T? defaultValue;
  final double height;
  final Color? activeColor;

  const SilmPopupDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onSelected,
    this.prefixLabel,
    this.leadingIcon,
    this.tooltip,
    this.highlightWhenNotDefault = false,
    this.defaultValue,
    this.height = 38,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.firstWhere(
      (o) => o.value == value,
      orElse: () => options.first,
    );
    final isFiltered =
        highlightWhenNotDefault && defaultValue != null && value != defaultValue;
    final accent = activeColor ?? accentPetrol;

    return PopupMenuButton<T>(
      tooltip: tooltip ?? '',
      color: surfaceCard,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderSubtle, width: 0.8),
      ),
      offset: Offset(0, height + 4),
      onSelected: onSelected,
      itemBuilder: (context) {
        final entries = <PopupMenuEntry<T>>[];
        for (final opt in options) {
          if (opt.dividerBefore) {
            entries.add(const PopupMenuDivider(height: 1));
          }
          final isSel = opt.value == value;
          entries.add(
            PopupMenuItem<T>(
              value: opt.value,
              child: Row(
                children: [
                  if (opt.icon != null) ...[
                    Icon(
                      opt.icon,
                      size: 14,
                      color: isSel ? accent : textSecondary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? accent : textPrimary,
                            fontFamilyFallback: const ['Inter', '-apple-system'],
                          ),
                        ),
                        if (opt.subtitle != null &&
                            opt.subtitle!.isNotEmpty) ...[
                          Text(
                            opt.subtitle!,
                            style: TextStyle(
                              fontSize: 10,
                              color: textSecondary,
                              fontFamilyFallback: const ['Inter', '-apple-system'],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSel) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_rounded, size: 14, color: accent),
                  ],
                ],
              ),
            ),
          );
        }
        return entries;
      },
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isFiltered ? accent.withValues(alpha: 0.12) : surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFiltered ? accent : borderSubtle,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isVoxelDarkMode ? 0.2 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null || selected.icon != null) ...[
              Icon(
                leadingIcon ?? selected.icon,
                size: 14,
                color: isFiltered ? accent : textSecondary,
              ),
              const SizedBox(width: 7),
            ],
            if (prefixLabel != null && prefixLabel!.isNotEmpty) ...[
              Text(
                '$prefixLabel ',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamilyFallback: const ['Inter', '-apple-system'],
                ),
              ),
            ],
            Text(
              selected.label,
              style: TextStyle(
                color: isFiltered ? accent : textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                fontFamilyFallback: const ['Inter', '-apple-system'],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isFiltered ? accent : textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

Widget colorSwatchCircle(Color color,
    {double size = 10, bool isTransparent = false}) {
  final isLight = color.computeLuminance() > 0.65;
  final isVeryDark = color.a > 0 && color.computeLuminance() < 0.08;

  if (isTransparent || color.a == 0) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: textSecondary.withValues(alpha: 0.8),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.4,
          height: size * 0.4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(
        color: (isLight || isVeryDark)
            ? (isLight ? const Color(0xFF6B7280) : const Color(0xFF4B5563))
            : borderSubtle,
        width: (isLight || isVeryDark) ? 1.2 : 1.0,
      ),
    ),
  );
}

Future<VoxelColor?> showCustomColorDialog(
  BuildContext context, {
  String initialName = '',
  Color initialColor = const Color(0xFF2E8B98),
}) async {
  final nameController = TextEditingController(text: initialName);
  Color selected = initialColor;
  final hexController = TextEditingController(
    text:
        '#${selected.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
  );

  const presets = [
    Color(0xFFB87333), // Cobre
    Color(0xFFCD7F32), // Bronce
    Color(0xFF00A896), // Turquesa
    Color(0xFF54B689), // Menta
    Color(0xFFD81B60), // Magenta
    Color(0xFF3949AB), // Índigo
    Color(0xFF7B1FA2), // Violeta
    Color(0xFFE2725B), // Terracota
    Color(0xFFC67D0A), // Ocre
    Color(0xFF708238), // Oliva
    Color(0xFF4682B4), // Acero
    Color(0xFF2C3539), // Carbón
    Color(0xFFFF007F), // Fucsia
    Color(0xFF76FF03), // Neón
    Color(0xFF878787), // Titanio
    Color(0xFF3D2314), // Chocolate
    Color(0xFFD4AF37), // Oro
    Color(0xFFC0C0C0), // Silver
  ];

  return showDialog<VoxelColor>(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderSubtle),
            ),
            title: Row(
              children: [
                const Icon(Icons.palette_outlined,
                    color: accentPetrol, size: 20),
                const SizedBox(width: 8),
                Text(
                  'COLOR PERSONALIZADO',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: textPrimary, fontSize: 13),
                      decoration: fieldDecoration(
                        'Nombre del color',
                        hint: 'Ej: Cobre Metálico, Menta...',
                      ),
                      onChanged: (name) {
                        final match = voxelColorPalette.where(
                          (item) =>
                              item.name.toLowerCase() ==
                              name.trim().toLowerCase(),
                        );
                        if (match.isEmpty) return;
                        final color = Color(match.first.value);
                        setDialogState(() {
                          selected = color;
                          hexController.text =
                              '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        colorSwatchCircle(selected, size: 36),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: hexController,
                            style: TextStyle(
                              color: textPrimary,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            decoration:
                                fieldDecoration('Código HEX', hint: '#RRGGBB'),
                            onChanged: (val) {
                              try {
                                final clean = val.replaceAll('#', '').trim();
                                if (clean.length == 6) {
                                  final parsed = parseHex(clean);
                                  setDialogState(() => selected = parsed);
                                }
                              } catch (_) {}
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'MATICES PREDEFINIDOS',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((color) {
                        final isChosen =
                            selected.toARGB32() == color.toARGB32();
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selected = color;
                              hexController.text =
                                  '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isChosen ? textPrimary : borderSubtle,
                                width: isChosen ? 2.5 : 1.0,
                              ),
                              boxShadow: isChosen
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // RGB Sliders for precise tuning
                    _colorSlider(
                      'R',
                      (selected.r * 255).round().clamp(0, 255),
                      Colors.redAccent,
                      (val) {
                        setDialogState(() {
                          selected = Color.fromARGB(
                            255,
                            val,
                            (selected.g * 255).round().clamp(0, 255),
                            (selected.b * 255).round().clamp(0, 255),
                          );
                          hexController.text =
                              '#${selected.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                        });
                      },
                    ),
                    _colorSlider(
                      'G',
                      (selected.g * 255).round().clamp(0, 255),
                      Colors.greenAccent,
                      (val) {
                        setDialogState(() {
                          selected = Color.fromARGB(
                            255,
                            (selected.r * 255).round().clamp(0, 255),
                            val,
                            (selected.b * 255).round().clamp(0, 255),
                          );
                          hexController.text =
                              '#${selected.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                        });
                      },
                    ),
                    _colorSlider(
                      'B',
                      (selected.b * 255).round().clamp(0, 255),
                      Colors.blueAccent,
                      (val) {
                        setDialogState(() {
                          selected = Color.fromARGB(
                            255,
                            (selected.r * 255).round().clamp(0, 255),
                            (selected.g * 255).round().clamp(0, 255),
                            val,
                          );
                          hexController.text =
                              '#${selected.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancelar', style: TextStyle(color: textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim().isEmpty
                      ? 'Personalizado ${hexController.text}'
                      : nameController.text.trim();
                  final hex = hexController.text.startsWith('#')
                      ? hexController.text.toUpperCase()
                      : '#${hexController.text.toUpperCase()}';
                  Navigator.pop(
                    dialogCtx,
                    VoxelColor(
                        name: name, hex: hex, value: selected.toARGB32()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentPetrol,
                  foregroundColor: textPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Usar Color'),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _colorSlider(
    String label, int value, Color activeColor, ValueChanged<int> onChanged) {
  return Row(
    children: [
      SizedBox(
        width: 18,
        child: Text(
          label,
          style: TextStyle(
              color: activeColor, fontWeight: FontWeight.w800, fontSize: 11),
        ),
      ),
      Expanded(
        child: SliderTheme(
          data: SliderThemeData(
            thumbColor: activeColor,
            activeTrackColor: activeColor,
            inactiveTrackColor: surfaceElevated,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            min: 0,
            max: 255,
            value: value.toDouble(),
            onChanged: (val) => onChanged(val.round()),
          ),
        ),
      ),
      SizedBox(
        width: 28,
        child: Text(
          '$value',
          textAlign: TextAlign.end,
          style: TextStyle(color: textMuted, fontSize: 10),
        ),
      ),
    ],
  );
}
