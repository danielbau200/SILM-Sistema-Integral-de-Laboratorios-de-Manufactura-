import 'dart:async';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart' as share_plus;
import 'controllers.dart';
import 'database.dart';
import 'models.dart';
import 'theme.dart';

void toast(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isError ? semanticDanger : borderSubtle),
      ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? semanticDanger : semanticSuccess,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ));
}

void goBack(BuildContext context) => Navigator.of(context).maybePop();

Widget techButton(
  String text,
  VoidCallback? onPressed, {
  Color color = accentPetrol,
  Color foreground = textPrimary,
  IconData? icon,
  bool isOutlined = false,
  double height = 44,
}) {
  return MouseRegion(
    cursor: onPressed != null
        ? SystemMouseCursors.click
        : SystemMouseCursors.basic,
    child: SizedBox(
      height: height,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon ?? Icons.check, size: 16),
              label: Text(
                text.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: const BorderSide(color: borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon ?? Icons.check, size: 16),
              label: Text(
                text.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: foreground,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
    ),
  );
}

String dateText(int milliseconds, {bool short = false}) {
  final d = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return short
      ? '$day/$month/${d.year.toString().substring(2)}'
      : '$day/$month/${d.year}';
}

// ==========================================
// 1. PANTALLA DE LOGIN
// ==========================================
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> with RestorationMixin {
  final user = RestorableTextEditingController();
  final password = RestorableTextEditingController();
  final userFocus = FocusNode(), passwordFocus = FocusNode();
  bool _passwordVisible = false;

  @override
  String? get restorationId => 'login';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(user, 'user');
    registerForRestoration(password, 'password');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  void _openKeyboard(FocusNode focusNode) {
    focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && focusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      }
    });
  }

  void _login() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (user.value.text.trim().isEmpty || password.value.text.trim().isEmpty) {
      toast(context, 'Faltan datos de acceso', isError: true);
      return;
    }
    if ((user.value.text.trim().toLowerCase() == 'admin' ||
            user.value.text.trim().toLowerCase() == 'admin@voxel.com') &&
        password.value.text.trim() == 'admin123') {
      widget.onLoginSuccess();
      return;
    }
    toast(context, 'Credenciales incorrectas. Usa admin / admin123',
        isError: true);
  }

  @override
  void dispose() {
    user.dispose();
    password.dispose();
    userFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: bgBase,
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.2,
              colors: [Color(0xFF1B2027), bgBase],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderSubtle),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accentPetrol.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.precision_manufacturing_outlined,
                            size: 28,
                            color: accentPetrol,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'VOXELCOST3D',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'SISTEMA DE CONTROL DE FABRICACIÓN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: user.value,
                        focusNode: userFocus,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        onTap: () => _openKeyboard(userFocus),
                        onEditingComplete: () => passwordFocus.requestFocus(),
                        style: const TextStyle(color: textPrimary, fontSize: 13),
                        decoration: fieldDecoration(
                          'Operador / ID',
                          hint: 'admin',
                          prefix: const Icon(Icons.person_outline,
                              color: textSecondary, size: 18),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: password.value,
                        focusNode: passwordFocus,
                        keyboardType: TextInputType.visiblePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        obscureText: !_passwordVisible,
                        textInputAction: TextInputAction.done,
                        onTap: () => _openKeyboard(passwordFocus),
                        onSubmitted: (_) => _login(),
                        style: const TextStyle(color: textPrimary, fontSize: 13),
                        decoration: fieldDecoration(
                          'Contraseña',
                          hint: 'admin123',
                          prefix: const Icon(Icons.lock_outline,
                              color: textSecondary, size: 18),
                          suffix: IconButton(
                            tooltip: _passwordVisible
                                ? 'Ocultar contraseña'
                                : 'Mostrar contraseña',
                            onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible),
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: textSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      techButton(
                        'ACCEDER AL TALLER',
                        _login,
                        icon: Icons.login,
                        height: 46,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

// ==========================================
// 2. PANTALLA PRINCIPAL (DASHBOARD)
// ==========================================
enum ActivePanel {
  welcome,
  printHistory,
  inventory,
  analytics,
  export,
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const HomeScreen({super.key, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPinned = false;
  bool _isHovered = false;
  ActivePanel _activePanel = ActivePanel.welcome;
  Timer? _menuCloseTimer;
  late final PrintViewModel printVm = PrintViewModel(AppDatabase());
  late final InventoryViewModel inventoryVm = InventoryViewModel(AppDatabase());

  @override
  void dispose() {
    _menuCloseTimer?.cancel();
    printVm.dispose();
    inventoryVm.dispose();
    super.dispose();
  }

  void _selectPanel(ActivePanel panel) {
    _menuCloseTimer?.cancel();
    setState(() {
      _activePanel = panel;
      _isPinned = false;
      _isHovered = false;
    });
  }

  void _togglePinned() {
    _menuCloseTimer?.cancel();
    setState(() {
      if (_isPinned) {
        _isPinned = false;
        _isHovered = false;
      } else {
        _isPinned = true;
        _isHovered = false;
      }
    });
  }

  void _onHoverMenu(bool hovered) {
    if (_isPinned) return;
    _menuCloseTimer?.cancel();
    if (hovered) {
      if (!_isHovered) {
        setState(() {
          _isHovered = true;
        });
      }
    } else {
      // Período de gracia de 350ms para que al mover el cursor hacia arriba,
      // hacia los lados o por el encabezado el menú se mantenga abierto sin cerrarse bruscamente.
      _menuCloseTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted && !_isPinned && _isHovered) {
          setState(() {
            _isHovered = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showMenu = _isPinned || _isHovered;

    return Scaffold(
      backgroundColor: bgBase,
      body: Stack(
        children: [
          // 1. Capa del Panel:
          // Cuando se da clic (_isPinned == true), el spacer empuja el panel a la derecha.
          // En estado normal o hover, el panel está a pantalla completa.
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                width: _isPinned ? 320 : 0,
              ),
              Expanded(
                child: _buildCurrentPanel(),
              ),
            ],
          ),

          // 2. Capa del Menú Lateral:
          // Se despliega de izquierda a derecha apareciendo simultáneamente de invisible (0%) a totalmente opaco (100%).
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 320,
            child: IgnorePointer(
              ignoring: !showMenu,
              child: MouseRegion(
                onEnter: (_) => _onHoverMenu(true),
                onExit: (_) => _onHoverMenu(false),
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  offset: showMenu ? Offset.zero : const Offset(-1.0, 0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    opacity: showMenu ? 1.0 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceCard,
                        border: const Border(
                          right: BorderSide(color: borderSubtle),
                        ),
                        boxShadow: (_isHovered && !_isPinned)
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(4, 0),
                                ),
                              ]
                            : null,
                      ),
                      child: _buildSidebar(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPanel() {
    switch (_activePanel) {
      case ActivePanel.welcome:
        return _buildWelcomePanel(context);
      case ActivePanel.printHistory:
        return PrintHistoryScreen(
          onToggleMenu: _togglePinned,
          onHoverMenu: () => _onHoverMenu(true),
          isPinned: _isPinned,
          vm: printVm,
          inventoryVm: inventoryVm,
        );
      case ActivePanel.inventory:
        return InventoryScreen(
          onToggleMenu: _togglePinned,
          onHoverMenu: () => _onHoverMenu(true),
          isPinned: _isPinned,
          vm: inventoryVm,
        );
      case ActivePanel.analytics:
        return AnalyticsScreen(
          onToggleMenu: _togglePinned,
          onHoverMenu: () => _onHoverMenu(true),
          isPinned: _isPinned,
          vm: printVm,
          inventoryVm: inventoryVm,
        );
      case ActivePanel.export:
        return ExportScreen(
          onToggleMenu: _togglePinned,
          onHoverMenu: () => _onHoverMenu(true),
          isPinned: _isPinned,
          vm: printVm,
          inventoryVm: inventoryVm,
        );
    }
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      color: surfaceCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header del Menú - alineado exactamente con la coordenada y dimensiones del AppBar (56px)
          Container(
            height: kToolbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: const BoxDecoration(
              color: bgBase,
              border: Border(bottom: BorderSide(color: borderSubtle)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: kToolbarHeight,
                  child: IconButton(
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    mouseCursor: SystemMouseCursors.click,
                    icon: const SidebarToggleIcon(),
                    onPressed: _togglePinned,
                  ),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'MENÚ PRINCIPAL',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: semanticSuccess.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: semanticSuccess.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle,
                          size: 5, color: semanticSuccess),
                      SizedBox(width: 5),
                      Text(
                        'OPERATIVO',
                        style: TextStyle(
                          color: semanticSuccess,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Opciones de navegación
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 8, top: 4),
                  child: Text(
                    'MÓDULOS DE GESTIÓN',
                    style: TextStyle(
                      color: textSecondary.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _sidebarOptionCard(
                  title: 'Registro de Impresiones',
                  icon: Icons.view_in_ar_rounded,
                  isActive: _activePanel == ActivePanel.printHistory,
                  onTap: () => _selectPanel(ActivePanel.printHistory),
                ),
                _sidebarOptionCard(
                  title: 'Inventario de Materiales',
                  icon: Icons.inventory_2_rounded,
                  isActive: _activePanel == ActivePanel.inventory,
                  onTap: () => _selectPanel(ActivePanel.inventory),
                ),
                _sidebarOptionCard(
                  title: 'Análisis de Producción',
                  icon: Icons.bar_chart_rounded,
                  isActive: _activePanel == ActivePanel.analytics,
                  onTap: () => _selectPanel(ActivePanel.analytics),
                ),
                _sidebarOptionCard(
                  title: 'Exportar',
                  icon: Icons.download_rounded,
                  isActive: _activePanel == ActivePanel.export,
                  onTap: () => _selectPanel(ActivePanel.export),
                ),
              ],
            ),
          ),

          // Pie del Menú con Cerrar Sesión
          const Divider(color: borderSubtle, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: widget.onLogout,
                  borderRadius: BorderRadius.circular(8),
                  mouseCursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, size: 16, color: textSecondary),
                        SizedBox(width: 8),
                        Text(
                          'CERRAR SESIÓN',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'VoxelCost 3D · Control de Taller',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarOptionCard({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(8),
            hoverColor: isActive
                ? accentPetrol.withValues(alpha: 0.18)
                : surfaceElevated,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? accentPetrol.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isActive ? accentPetrol : textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isActive ? accentPetrol : textPrimary,
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: accentPetrol,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  else
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: textMuted,
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildWelcomePanel(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([printVm, inventoryVm]),
      builder: (context, _) {
        final latest = printVm.latestRecord;
        final lowStock = inventoryVm.lowStockItems;

        return Scaffold(
          backgroundColor: bgBase,
          appBar: darkAppBar(
            'PANEL PRINCIPAL',
            _togglePinned,
            leadingWidget: const SidebarToggleIcon(),
            onHoverEnter: () => _onHoverMenu(true),
            onHoverExit: () => _onHoverMenu(false),
            hideLeading: _isPinned,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                children: [
                  // Cabecera compacta con saludo industrial
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: accentPetrol.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.layers_outlined,
                              size: 24, color: accentPetrol),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VOXELCOST 3D · SISTEMA DE CONTROL DE FABRICACIÓN',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '¡BIENVENIDO!',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        techButton(
                          'NUEVA IMPRESIÓN',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrintFormScreen(
                                vm: printVm,
                                inventoryVm: inventoryVm,
                              ),
                            ),
                          ),
                          icon: Icons.add_circle_outline,
                          color: accentPetrol,
                          height: 38,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Resumen Rápido (4 Tarjetas)
                  LayoutBuilder(builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 650;
                    final cardWidth = isNarrow
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 12) / 2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _welcomeMetricCard(
                            title: 'CONSUMO TOTAL',
                            value: '${printVm.totalGrams.toStringAsFixed(1)} g',
                            subtitle:
                                '${printVm.totalPlaGrams.toStringAsFixed(0)}g PLA · ${printVm.totalPetgGrams.toStringAsFixed(0)}g PETG',
                            icon: Icons.scale_outlined,
                            iconColor: accentPetrol,
                            badgeText: '${printVm.totalPieces} piezas',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _welcomeMetricCard(
                            title: 'PIEZAS FABRICADAS',
                            value: '${printVm.totalPieces} piezas',
                            subtitle:
                                '${printVm.totalPrints} registros técnicos en historial',
                            icon: Icons.precision_manufacturing_outlined,
                            iconColor: accentAmber,
                            badgeText:
                                printVm.totalPieces > 0 ? 'Activo' : 'Sin piezas',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _welcomeMetricCard(
                            title: 'ESTADO DE STOCK',
                            value: lowStock.isEmpty
                                ? 'Niveles Óptimos'
                                : '${lowStock.length} Bajo Stock',
                            subtitle: lowStock.isEmpty
                                ? 'Todas las bobinas con stock > 20%'
                                : lowStock
                                    .map((i) =>
                                        '${i.material} ${i.color} (${i.stockActual.toInt()}g)')
                                    .join(', '),
                            icon: lowStock.isEmpty
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            iconColor: lowStock.isEmpty
                                ? semanticSuccess
                                : semanticDanger,
                            isAlert: lowStock.isNotEmpty,
                            badgeText: lowStock.isEmpty ? 'OK' : 'ATENCIÓN',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _welcomeLastPrintCard(latest),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _welcomeMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    String? badgeText,
    bool isAlert = false,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAlert
                ? semanticDanger.withValues(alpha: 0.5)
                : borderSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isAlert ? semanticDanger : accentPetrol)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: (isAlert ? semanticDanger : accentPetrol)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: isAlert ? semanticDanger : accentPetrol,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: isAlert ? semanticDanger : textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

  Widget _welcomeLastPrintCard(PrintRecord? latest) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_toggle_off_outlined,
                      size: 18, color: accentPetrol),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ÚLTIMA PIEZA REGISTRADA',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (latest != null)
                  Text(
                    dateText(latest.date, short: true),
                    style: const TextStyle(color: textMuted, fontSize: 10),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (latest == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Aún no hay impresiones registradas',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      latest.pieceType,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (latest.cantidad > 1) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentAmber.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: accentAmber.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '×${latest.cantidad}',
                        style: const TextStyle(
                          color: accentAmber,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Categoría: ${latest.figureCategory} · ${latest.totalGrams.toStringAsFixed(1)}g total${latest.cantidad > 1 ? ' (${latest.unitGrams.toStringAsFixed(1)}g c/u)' : ''}',
                style: const TextStyle(color: textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: latest.materials.map((m) {
                  final colorObj =
                      findVoxelColor(value: m.color, name: m.colorName);
                  final itemTotalGrams = m.grams * latest.cantidad;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      colorSwatchCircle(colorObj.color,
                          size: 8, isTransparent: colorObj.isTransparent),
                      const SizedBox(width: 4),
                      Text(
                        latest.cantidad > 1
                            ? '${m.type} (${itemTotalGrams.toStringAsFixed(1)}g)'
                            : '${m.type} (${m.grams.toStringAsFixed(1)}g)',
                        style: const TextStyle(
                            color: textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      );
}

// ==========================================
// 3. HISTORIAL TÉCNICO DE IMPRESIONES
// ==========================================
class PrintHistoryScreen extends StatefulWidget {
  final VoidCallback? onToggleMenu;
  final VoidCallback? onHoverMenu;
  final bool isPinned;
  final PrintViewModel? vm;
  final InventoryViewModel? inventoryVm;
  const PrintHistoryScreen({
    super.key,
    this.onToggleMenu,
    this.onHoverMenu,
    this.isPinned = false,
    this.vm,
    this.inventoryVm,
  });
  @override
  State<PrintHistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends State<PrintHistoryScreen> {
  late final PrintViewModel vm;
  late final InventoryViewModel inventoryVm;
  bool _ownsVm = false;
  bool _ownsInvVm = false;

  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'Todos'; // 'Todos', 'PLA', 'PETG', 'Este mes'

  @override
  void initState() {
    super.initState();
    if (widget.vm != null) {
      vm = widget.vm!;
    } else {
      vm = PrintViewModel(AppDatabase());
      _ownsVm = true;
    }
    if (widget.inventoryVm != null) {
      inventoryVm = widget.inventoryVm!;
    } else {
      inventoryVm = InventoryViewModel(AppDatabase());
      _ownsInvVm = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsVm) vm.dispose();
    if (_ownsInvVm) inventoryVm.dispose();
    super.dispose();
  }

  List<PrintRecord> _getFilteredRecords() {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    return vm.allRecords.where((r) {
      // 1. Filtro por Chips
      if (_activeFilter == 'PLA') {
        if (!r.materials.any((m) => m.type.toUpperCase() == 'PLA')) return false;
      } else if (_activeFilter == 'PETG') {
        if (!r.materials.any((m) => m.type.toUpperCase() == 'PETG')) return false;
      } else if (_activeFilter == 'Este mes') {
        final d = DateTime.fromMillisecondsSinceEpoch(r.date);
        if (d.year != now.year || d.month != now.month) return false;
      }

      // 2. Filtro por búsqueda (nombre o color)
      if (query.isNotEmpty) {
        final matchPiece = r.pieceType.toLowerCase().contains(query);
        final matchCategory = r.figureCategory.toLowerCase().contains(query);
        final matchNotes = (r.notes ?? '').toLowerCase().contains(query);
        final matchMaterial = r.materials.any((m) {
          final cName = (m.colorName ?? '').toLowerCase();
          final mType = m.type.toLowerCase();
          final colorObj = findVoxelColor(value: m.color, name: m.colorName);
          return cName.contains(query) ||
              mType.contains(query) ||
              colorObj.name.toLowerCase().contains(query);
        });
        if (!matchPiece && !matchCategory && !matchNotes && !matchMaterial) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([vm, inventoryVm]),
        builder: (_, __) {
          final filtered = _getFilteredRecords();

          return Scaffold(
            appBar: darkAppBar(
              'HISTORIAL TÉCNICO',
              widget.onToggleMenu ?? () => goBack(context),
              leadingWidget: widget.onToggleMenu != null
                  ? const SidebarToggleIcon()
                  : null,
              leadingIcon: Icons.arrow_back,
              onHoverEnter: widget.onHoverMenu,
              hideLeading: widget.isPinned,
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PrintFormScreen(vm: vm, inventoryVm: inventoryVm),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 16, color: textPrimary),
                    label: const Text('Nueva impresión',
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      backgroundColor: surfaceElevated,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: borderSubtle),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            backgroundColor: bgBase,
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: double.infinity),
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [

                    // 2. Barra de búsqueda y chips de filtro
                    _searchAndFilterRow(),
                    const SizedBox(height: 16),

                    if (vm.error != null) ...[
                      _databaseError(vm.error!),
                      const SizedBox(height: 14),
                    ],

                    // 3. Encabezados de Tabla: PIEZA | CANT. | FILAMENTO
                    _tableHeader(),
                    const SizedBox(height: 8),

                    // 4. Lista de Registros
                    if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(48),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.layers_clear_outlined,
                                size: 40, color: textMuted),
                            const SizedBox(height: 12),
                            Text(
                              vm.allRecords.isEmpty
                                  ? 'No hay impresiones registradas en el historial'
                                  : 'No se encontraron registros que coincidan con la búsqueda o filtro',
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...filtered.map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _recordRow(context, vm, record),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Widget _databaseError(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: semanticDanger.withValues(alpha: 0.12),
          border: Border.all(color: semanticDanger.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: semanticDanger, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: semanticDanger, fontSize: 13),
              ),
            ),
          ],
        ),
      );


  Widget _searchAndFilterRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 620;

      final searchField = TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: textPrimary, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Buscar pieza o color',
          hintStyle: const TextStyle(color: textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 18, color: textMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16, color: textMuted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: surfaceElevated,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accentPetrol, width: 1.5),
          ),
        ),
      );

      final filterChips = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _filterChip('Todos'),
          const SizedBox(width: 8),
          _filterChip('PLA'),
          const SizedBox(width: 8),
          _filterChip('PETG'),
          const SizedBox(width: 8),
          _filterChip('Este mes'),
        ],
      );

      if (isNarrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: filterChips,
            ),
          ],
        );
      } else {
        return Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 14),
            filterChips,
          ],
        );
      }
    });
  }

  Widget _filterChip(String label) {
    final isSelected = _activeFilter == label;
    return InkWell(
      onTap: () => setState(() => _activeFilter = label),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? surfaceElevated
              : bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? textSecondary : borderSubtle,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? textPrimary : textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 24),
          Text(
            'PIEZA',
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          Spacer(),
          SizedBox(
            width: 100,
            child: Text(
              'FILAMENTO',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _recordRow(BuildContext context, PrintViewModel vm, PrintRecord r) {
    return _PrintRecordRow(
      record: r,
      vm: vm,
      inventoryVm: inventoryVm,
      onDelete: (rec) => _confirmDeleteRecord(context, vm, inventoryVm, rec),
    );
  }

  void _confirmDeleteRecord(
    BuildContext context,
    PrintViewModel vm,
    InventoryViewModel inventoryVm,
    PrintRecord r,
  ) {
    bool returnToStock = true;
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: borderSubtle),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: semanticDanger, size: 22),
              SizedBox(width: 8),
              Text(
                'Eliminar Registro',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Eliminar "${r.pieceType}"? Esta acción no se puede deshacer.',
                style: const TextStyle(color: textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: returnToStock,
                      activeColor: accentPetrol,
                      checkColor: Colors.white,
                      onChanged: (val) {
                        setDialogState(() {
                          returnToStock = val ?? false;
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Devolver filamento al inventario',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancelar',
                  style: TextStyle(color: textSecondary, fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                if (returnToStock) {
                  for (final m in r.materials) {
                    inventoryVm.restoreGrams(
                      m.type,
                      m.grams * r.cantidad,
                      colorName: m.colorName,
                      colorValue: m.color,
                    );
                  }
                }
                await vm.deleteRecord(r);
                if (context.mounted) {
                  toast(
                    context,
                    returnToStock
                        ? 'Registro eliminado y ${r.totalGrams.toStringAsFixed(1)} g devueltos al inventario'
                        : 'Registro eliminado',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: semanticDanger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Eliminar',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialColorEntry {
  final String type;
  final VoxelColor voxelColor;
  final String fullName;

  _MaterialColorEntry({
    required this.type,
    required this.voxelColor,
    required this.fullName,
  });
}

class _PrintRecordRow extends StatefulWidget {
  final PrintRecord record;
  final PrintViewModel vm;
  final InventoryViewModel inventoryVm;
  final void Function(PrintRecord record) onDelete;

  const _PrintRecordRow({
    required this.record,
    required this.vm,
    required this.inventoryVm,
    required this.onDelete,
  });

  @override
  State<_PrintRecordRow> createState() => _PrintRecordRowState();
}

class _PrintRecordRowState extends State<_PrintRecordRow> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final isTouchDevice = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final showActions = _isHovered || _isFocused || isTouchDevice;

    // Obtener lista única de materiales y colores
    final List<_MaterialColorEntry> distinctMaterials = [];
    final Set<String> seenKeys = {};

    for (final m in r.materials) {
      final vColor = findVoxelColor(value: m.color, name: m.colorName);
      final colorName = (m.colorName != null && m.colorName!.trim().isNotEmpty)
          ? m.colorName!.trim()
          : vColor.name;
      final fullName = '${m.type} $colorName'.trim();
      final key = '${m.type.trim().toUpperCase()}_${vColor.value}_$colorName';

      if (!seenKeys.contains(key)) {
        seenKeys.add(key);
        distinctMaterials.add(_MaterialColorEntry(
          type: m.type,
          voxelColor: vColor,
          fullName: fullName,
        ));
      }
    }

    if (distinctMaterials.isEmpty) {
      final fallback = findVoxelColor(hex: '#888887');
      distinctMaterials.add(_MaterialColorEntry(
        type: 'Material',
        voxelColor: fallback,
        fullName: 'Material',
      ));
    }

    final primaryColor = distinctMaterials.first.voxelColor;
    final dateStr = dateText(r.date);
    final isMultiQty = r.cantidad > 1;

    final totalGramsStr = r.totalGrams % 1 == 0
        ? '${r.totalGrams.toInt()} g'
        : '${r.totalGrams.toStringAsFixed(1)} g';

    final unitGramsStr = r.unitGrams % 1 == 0
        ? '${r.unitGrams.toInt()} g c/u'
        : '${r.unitGrams.toStringAsFixed(1)} g c/u';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? surfaceElevated.withValues(alpha: 0.7)
                : surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered ? borderStrong : borderSubtle,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Punto de color simple (lado izquierdo)
              colorSwatchCircle(
                primaryColor.color,
                size: 12,
                isTransparent: primaryColor.isTransparent,
              ),
              const SizedBox(width: 12),

              // 2. Columna de Pieza: Nombre integrado con cantidad + Materiales (texto o swatches)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fila superior: Título con cantidad y categoría
                    Row(
                      children: [
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              text: r.pieceType,
                              style: const TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              children: [
                                if (isMultiQty)
                                  TextSpan(
                                    text: ' · × ${r.cantidad} uds',
                                    style: TextStyle(
                                      color: textPrimary.withValues(alpha: 0.8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showActions && r.figureCategory.trim().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: borderSubtle),
                            ),
                            child: Text(
                              r.figureCategory,
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (showActions) ...[
                      const SizedBox(height: 4),
                      // Fila inferior: Fecha y material(es)
                      _buildMaterialSubtitle(dateStr, distinctMaterials),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // 3. Filamento: Gramos totales y unitarios
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      totalGramsStr,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showActions && isMultiQty) ...[
                      const SizedBox(height: 1),
                      Text(
                        unitGramsStr,
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 4. Acciones: Menú de tres puntos con transición suave de opacidad (180ms)
              SizedBox(
                width: 32,
                height: 32,
                child: AnimatedOpacity(
                  opacity: showActions ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  child: IgnorePointer(
                    ignoring: !showActions,
                    child: PopupMenuButton<String>(
                      tooltip: 'Opciones',
                      color: surfaceCard,
                      elevation: 6,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert,
                          size: 18, color: textSecondary),
                      constraints: const BoxConstraints(minWidth: 130),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: borderSubtle),
                      ),
                      onSelected: (val) {
                        if (val == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrintFormScreen(
                                vm: widget.vm,
                                inventoryVm: widget.inventoryVm,
                                record: r,
                              ),
                            ),
                          );
                        } else if (val == 'delete') {
                          widget.onDelete(r);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          height: 36,
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 16, color: textPrimary),
                              SizedBox(width: 8),
                              Text('Editar',
                                  style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        const PopupMenuItem(
                          value: 'delete',
                          height: 36,
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 16, color: semanticDanger),
                              SizedBox(width: 8),
                              Text('Eliminar',
                                  style: TextStyle(
                                      color: semanticDanger,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialSubtitle(
      String dateStr, List<_MaterialColorEntry> materials) {
    if (materials.length <= 1) {
      // 1 solo material/color: texto normal
      return Text(
        '$dateStr · ${materials.first.fullName}',
        style: const TextStyle(
          color: textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // 2 o más materiales/colores: fila compacta de swatches
    final List<Widget> swatches = [];
    final bool hasOverflow = materials.length > 6;
    final int displayCount = hasOverflow ? 5 : materials.length;

    for (int i = 0; i < displayCount; i++) {
      final m = materials[i];
      swatches.add(
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Tooltip(
            message: m.fullName,
            waitDuration: const Duration(milliseconds: 250),
            child: colorSwatchCircle(
              m.voxelColor.color,
              size: 10,
              isTransparent: m.voxelColor.isTransparent,
            ),
          ),
        ),
      );
    }

    if (hasOverflow) {
      final remainingCount = materials.length - 5;
      final remainingNames =
          materials.skip(5).map((m) => m.fullName).join('\n');
      swatches.add(
        Tooltip(
          message: remainingNames,
          waitDuration: const Duration(milliseconds: 250),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderSubtle),
            ),
            child: Text(
              '+$remainingCount',
              style: const TextStyle(
                color: textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$dateStr · ',
          style: const TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
        ...swatches,
      ],
    );
  }
}

// ==========================================
// 4. REGISTRO / EDICIÓN DE IMPRESIÓN
// ==========================================
class PrintFormScreen extends StatefulWidget {
  final PrintViewModel vm;
  final InventoryViewModel? inventoryVm;
  final PrintRecord? record;
  const PrintFormScreen(
      {super.key, required this.vm, this.inventoryVm, this.record});
  @override
  State<PrintFormScreen> createState() => _FormState();
}

class _FormState extends State<PrintFormScreen> {
  late final InventoryViewModel inventoryVm;
  bool _ownsInvVm = false;
  late TextEditingController name, notes, customCategory;
  late TextEditingController qtyController;
  int cantidad = 1;
  String? category;
  DateTime selectedDate = DateTime.now();
  final categories = [
    'Pieza Funcional',
    'Arte / Decorativo',
    'Prototipo',
    'Repuesto',
    'Miniatura',
    'Otro'
  ];
  final types = [
    'PLA',
    'PETG',
    'ABS',
    'TPU',
    'ASA',
    'Nylon',
    'Carbon Fiber',
    'Resina',
    'Otro'
  ];
  late List<_MaterialForm> materials;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.inventoryVm != null) {
      inventoryVm = widget.inventoryVm!;
    } else {
      inventoryVm = InventoryViewModel(AppDatabase());
      _ownsInvVm = true;
    }

    final r = widget.record;
    name = TextEditingController(text: r?.pieceType ?? '');
    notes = TextEditingController(text: r?.notes ?? '');
    cantidad = r?.cantidad ?? 1;
    if (cantidad < 1) cantidad = 1;
    qtyController = TextEditingController(text: '$cantidad');

    if (r != null) {
      final savedCategory = r.figureCategory;
      if (categories.contains(savedCategory)) {
        category = savedCategory;
      } else {
        category = 'Otro';
      }
      customCategory = TextEditingController(
          text: category == 'Otro' ? savedCategory : '');
    } else {
      category = null;
      customCategory = TextEditingController();
    }

    selectedDate = r == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(r.date);
    materials = r?.materials
            .map((m) => _MaterialForm(
                types.contains(m.type) ? m.type : 'Otro',
                m.grams == 0 ? '' : '${m.grams}',
                m.color,
                m.colorName ?? '',
                m.combine,
                customType: types.contains(m.type) ? '' : m.type))
            .toList() ??
        [
          _MaterialForm('PLA', '', null, '', true),
        ];
  }

  @override
  void dispose() {
    name.dispose();
    notes.dispose();
    customCategory.dispose();
    qtyController.dispose();
    for (final material in materials) {
      material.dispose();
    }
    if (_ownsInvVm) inventoryVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: inventoryVm,
        builder: (context, _) => Scaffold(
          appBar: darkAppBar(
            widget.record == null
                ? 'REGISTRO DE IMPRESIÓN'
                : 'EDITAR IMPRESIÓN',
            () => goBack(context),
          ),
          backgroundColor: bgBase,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  formCard(
                    title: 'Información de la Pieza',
                    subtitle: 'Datos técnicos del modelo fabricado',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre de la pieza a la mitad de la pantalla
                        LayoutBuilder(
                          builder: (context, constraints) => SizedBox(
                            width: constraints.maxWidth > 500
                                ? constraints.maxWidth * 0.5
                                : double.infinity,
                            child: TextField(
                              controller: name,
                              style: const TextStyle(
                                  color: textPrimary, fontSize: 13),
                              decoration: fieldDecoration('Nombre de la pieza *',
                                  hint: 'Ej: Engrane reductor v2'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Categoría a la medida de la opción más larga ("Arte / Decorativo")
                        SizedBox(
                          width: 230,
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            dropdownColor: surfaceElevated,
                            style: const TextStyle(
                                color: textPrimary, fontSize: 13),
                            iconEnabledColor: textSecondary,
                            hint: const Text('Selecciona una categoría *',
                                style: TextStyle(color: textMuted, fontSize: 13)),
                            decoration: fieldDecoration('Categoría *'),
                            items: categories
                                .map((x) =>
                                    DropdownMenuItem(value: x, child: Text(x)))
                                .toList(),
                            onChanged: (x) => setState(() => category = x),
                          ),
                        ),
                        if (category == 'Otro') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 230,
                            child: TextField(
                              controller: customCategory,
                              style: const TextStyle(
                                  color: textPrimary, fontSize: 13),
                              decoration: fieldDecoration(
                                  'Categoría personalizada *'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Fecha de fabricación a medida
                        SizedBox(
                          width: 230,
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                initialDate: selectedDate,
                                builder: (context, child) => Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: accentPetrol,
                                      onPrimary: textPrimary,
                                      surface: surfaceCard,
                                      onSurface: textPrimary,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (!mounted || picked == null) return;
                              setState(() => selectedDate = picked);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      size: 16, color: accentPetrol),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Fecha de fabricación',
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        dateText(selectedDate
                                            .millisecondsSinceEpoch),
                                        style: const TextStyle(
                                          color: textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.edit_calendar_outlined,
                                      size: 16, color: textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Campo "Cantidad de piezas" de tamaño máximo 2 caracteres
                        _buildQuantityStepper(),
                        const SizedBox(height: 10),

                        // Resumen en vivo contenido a medida
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: _buildLiveConsumptionSummary(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  formCard(
                    title: 'Materiales Utilizados',
                    subtitle: 'Gramos consumidos POR UNIDAD de pieza individual',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...materials.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _materialCard(entry.key, entry.value),
                              ),
                            ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => materials.add(
                                  _MaterialForm(
                                      'PLA', '', null, '', true),
                                )),
                            icon: const Icon(Icons.add, size: 16, color: accentPetrol),
                            label: const Text(
                              'AGREGAR OTRO MATERIAL',
                              style: TextStyle(
                                color: accentPetrol,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              side: const BorderSide(color: accentPetrol, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: surfaceElevated,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  formCard(
                    title: 'Observaciones Adicionales',
                    subtitle: 'Parámetros de impresión, notas de calibración',
                    child: TextField(
                      controller: notes,
                      minLines: 2,
                      maxLines: 4,
                      style: const TextStyle(color: textPrimary, fontSize: 13),
                      decoration: fieldDecoration('Notas u observaciones'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  techButton(
                    'GUARDAR REGISTRO',
                    _save,
                    icon: Icons.save_outlined,
                    height: 46,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildQuantityStepper() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cantidad de piezas *',
            style: TextStyle(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 120,
                height: 40,
                decoration: BoxDecoration(
                  color: surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (cantidad > 1) {
                          setState(() {
                            cantidad--;
                            qtyController.text = '$cantidad';
                          });
                        }
                      },
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8)),
                      child: SizedBox(
                        width: 34,
                        height: 40,
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: cantidad > 1 ? textPrimary : textMuted,
                        ),
                      ),
                    ),
                    Container(width: 1, height: 22, color: borderSubtle),
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed >= 1) {
                            setState(() => cantidad = parsed.clamp(1, 999));
                          }
                        },
                      ),
                    ),
                    Container(width: 1, height: 22, color: borderSubtle),
                    InkWell(
                      onTap: () {
                        if (cantidad < 999) {
                          setState(() {
                            cantidad++;
                            qtyController.text = '$cantidad';
                          });
                        }
                      },
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(8)),
                      child: const SizedBox(
                        width: 34,
                        height: 40,
                        child: Icon(
                          Icons.add,
                          size: 16,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (cantidad > 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentAmber.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: accentAmber.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'Lote de $cantidad unidades',
                    style: const TextStyle(
                      color: accentAmber,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );

  Widget _buildLiveConsumptionSummary() {
    final unitGrams = materials.fold(
        0.0, (s, m) => s + (double.tryParse(m.grams.text) ?? 0.0));
    final totalGrams = unitGrams * cantidad;

    if (unitGrams <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderSubtle),
        ),
        child: const Row(
          children: [
            Icon(Icons.scale_outlined, size: 16, color: textMuted),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ingresa los gramos de material para calcular el consumo total',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final String originText;
    if (cantidad > 1) {
      if (materials.length > 1) {
        originText =
            'Origen: ${unitGrams.toStringAsFixed(1)} g por pieza (${materials.length} materiales) × $cantidad piezas';
      } else {
        originText =
            'Origen: ${unitGrams.toStringAsFixed(1)} g por pieza × $cantidad piezas';
      }
    } else {
      if (materials.length > 1) {
        originText =
            'Origen: ${unitGrams.toStringAsFixed(1)} g sumando ${materials.length} materiales para 1 pieza';
      } else {
        originText = 'Origen: peso unitario de 1 pieza';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentPetrol.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentPetrol.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.scale_outlined,
                size: 16, color: accentPetrol),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      cantidad > 1
                          ? 'Consumo total del lote: '
                          : 'Consumo total de la pieza: ',
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${totalGrams.toStringAsFixed(1)} g',
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  originText,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _materialCard(int index, _MaterialForm m) {
    final effectiveType = m.type == 'Otro' ? m.customType : m.type;
    final enteredUnitGrams = double.tryParse(m.grams.text) ?? 0.0;
    final totalBatchGrams = enteredUnitGrams * cantidad;
    final currentStock = inventoryVm.getAvailableStock(
      effectiveType,
      colorName: m.colorName.isEmpty ? null : m.colorName,
      colorValue: m.color,
    );
    final isOverStock = totalBatchGrams > currentStock && currentStock > 0;
    final isStandardColor =
        m.color != null && voxelColorPalette.any((c) => c.value == m.color);

    int? dropdownColorValue;
    if (m.color == null && m.colorName.isEmpty) {
      dropdownColorValue = null;
    } else if (isStandardColor) {
      dropdownColorValue = m.color;
    } else {
      dropdownColorValue = -1;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MATERIAL ${index + 1}',
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              if (index > 0)
                InkWell(
                  onTap: () => setState(() => materials.removeAt(index)),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 16, color: semanticDanger),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              // Tipo de material a la medida de la opción más larga ("Carbon Fiber")
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('type_${index}_${m.type}'),
                  initialValue: types.contains(m.type) ? m.type : 'Otro',
                  dropdownColor: surfaceElevated,
                  style: const TextStyle(color: textPrimary, fontSize: 13),
                  iconEnabledColor: textSecondary,
                  decoration: fieldDecoration('Tipo *'),
                  items: types
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: (x) => setState(() => m.type = x!),
                ),
              ),
              // Color a la medida de la opción más larga ("Personalizado...", "Transparente"), vacío por default
              SizedBox(
                width: 205,
                child: DropdownButtonFormField<int?>(
                  key: ValueKey('color_${index}_${m.color}_${m.colorName}'),
                  initialValue: dropdownColorValue,
                  dropdownColor: surfaceElevated,
                  style: const TextStyle(color: textPrimary, fontSize: 13),
                  iconEnabledColor: textSecondary,
                  hint: const Text(
                    'Seleccionar...',
                    style: TextStyle(color: textMuted, fontSize: 13),
                  ),
                  decoration: fieldDecoration('Color *'),
                  items: [
                    ...voxelColorPalette.map((vc) => DropdownMenuItem<int?>(
                          value: vc.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              colorSwatchCircle(vc.color,
                                  size: 10, isTransparent: vc.isTransparent),
                              const SizedBox(width: 8),
                              Text(vc.name,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        )),
                    DropdownMenuItem<int?>(
                      value: -1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.palette_outlined,
                              size: 14, color: accentPetrol),
                          const SizedBox(width: 8),
                          Text(
                            !isStandardColor && m.colorName.isNotEmpty
                                ? m.colorName
                                : 'Personalizado...',
                            style: const TextStyle(
                              fontSize: 12,
                              color: accentPetrol,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) async {
                    if (val == -1) {
                      final picked = await showCustomColorDialog(
                        context,
                        initialColor: m.color != null
                            ? Color(m.color!)
                            : const Color(0xFF2563EB),
                        initialName: m.colorName,
                      );
                      if (mounted) {
                        if (picked != null) {
                          setState(() {
                            m.color = ((picked.color.a * 255).round() << 24) |
                                ((picked.color.r * 255).round() << 16) |
                                ((picked.color.g * 255).round() << 8) |
                                ((picked.color.b * 255).round());
                            m.colorName = picked.name;
                          });
                        } else {
                          setState(() {});
                        }
                      }
                    } else if (val != null) {
                      final selected =
                          voxelColorPalette.firstWhere((c) => c.value == val);
                      setState(() {
                        m.color = val;
                        m.colorName = selected.name;
                      });
                    }
                  },
                ),
              ),
              // Gramos c/u del tamaño para 4 caracteres
              SizedBox(
                width: 80,
                child: TextField(
                  controller: m.grams,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(4),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textPrimary, fontSize: 13),
                  decoration: fieldDecoration('Gramos *', hint: '0')
                      .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (m.type == 'Otro') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: 250,
              child: TextField(
                decoration:
                    fieldDecoration('Nombre del material personalizado *'),
                style: const TextStyle(color: textPrimary, fontSize: 13),
                onChanged: (x) => setState(() => m.customType = x),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgBase.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isOverStock
                    ? semanticWarning.withValues(alpha: 0.6)
                    : borderSubtle.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  currentStock > 0
                      ? Icons.inventory_2_outlined
                      : Icons.info_outline,
                  size: 13,
                  color: currentStock > 0
                      ? (currentStock <= 200 ? semanticWarning : textSecondary)
                      : textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    m.color == null && m.colorName.isEmpty
                        ? 'Selecciona un color para consultar el stock disponible'
                        : (cantidad > 1 && enteredUnitGrams > 0
                            ? 'Stock: ${currentStock.toStringAsFixed(1)} g · Lote: ${totalBatchGrams.toStringAsFixed(1)} g (${enteredUnitGrams.toStringAsFixed(1)}g × $cantidad)'
                            : 'Stock disponible: ${currentStock.toStringAsFixed(1)} g'),
                    style: TextStyle(
                      color: currentStock > 0
                          ? (currentStock <= 200
                              ? semanticWarning
                              : textSecondary)
                          : textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOverStock) ...[
                  const SizedBox(width: 6),
                  Text(
                    '¡Supera en ${(totalBatchGrams - currentStock).toStringAsFixed(1)}g!',
                    style: const TextStyle(
                      color: semanticWarning,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (name.text.trim().isEmpty) {
      toast(context, 'Falta el nombre de la pieza', isError: true);
      return;
    }
    if (category == null || category!.isEmpty) {
      toast(context, 'Selecciona una categoría para la pieza', isError: true);
      return;
    }
    final finalCategory =
        category == 'Otro' ? customCategory.text.trim() : category!;
    if (finalCategory.isEmpty) {
      toast(context, 'Especifica la categoría personalizada', isError: true);
      return;
    }

    final result = <MaterialData>[];
    bool hasOverStock = false;
    final overStockDetails = <String>[];

    for (final m in materials) {
      final type = m.type == 'Otro' ? m.customType : m.type;
      if (type.trim().isEmpty) {
        toast(context, 'Falta especificar el tipo de material', isError: true);
        return;
      }
      if (m.color == null && m.colorName.isEmpty) {
        toast(context, 'Falta seleccionar el color para el material $type',
            isError: true);
        return;
      }
      final g = double.tryParse(m.grams.text) ?? 0;
      if (g <= 0) {
        toast(
          context,
          'Ingresa los gramos consumidos por pieza para $type (debe ser mayor a 0)',
          isError: true,
        );
        return;
      }
      final avail = inventoryVm.getAvailableStock(
        type,
        colorName: m.colorName.isEmpty ? null : m.colorName,
        colorValue: m.color,
      );
      final totalBatch = g * cantidad;
      if (totalBatch > avail && avail > 0) {
        hasOverStock = true;
        overStockDetails.add(
            '$type (${m.colorName.isNotEmpty ? m.colorName : 'Color'}): requiere ${totalBatch.toStringAsFixed(1)}g ($g g × $cantidad) pero solo hay ${avail.toStringAsFixed(1)}g en inventario');
      }

      result.add(MaterialData(
        type: type,
        grams: g, // Gramos POR UNIDAD
        color: m.color ?? 0xFF808080,
        colorName: m.colorName.isEmpty ? null : m.colorName,
        combine: m.combine,
      ));
    }

    if (hasOverStock) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dlgCtx) => AlertDialog(
          backgroundColor: surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: borderSubtle),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: semanticWarning, size: 22),
              SizedBox(width: 8),
              Text(
                'Stock insuficiente',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Los gramos requeridos para el lote superan el stock en inventario:',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...overStockDetails.map((det) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $det',
                        style: const TextStyle(
                            color: semanticWarning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  )),
              const SizedBox(height: 12),
              const Text('¿Deseas guardar de todos modos?',
                  style: TextStyle(color: textPrimary, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dlgCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentPetrol,
                foregroundColor: textPrimary,
              ),
              child: const Text('Continuar y Guardar'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _saving = true);
    try {
      // En modo edición: restituir primero el consumo anterior del lote (gramos × cantidad anterior)
      if (widget.record != null) {
        final oldQty = widget.record!.cantidad;
        for (final oldM in widget.record!.materials) {
          await inventoryVm.restoreGrams(
            oldM.type,
            oldM.grams * oldQty,
            colorName: oldM.colorName,
            colorValue: oldM.color,
          );
        }
      }

      // Descontar nuevo consumo del lote (gramos × cantidad nueva)
      bool hasLowStockAlert = false;
      for (final newM in result) {
        final isLow = await inventoryVm.deductGrams(
          newM.type,
          newM.grams * cantidad,
          colorName: newM.colorName,
          colorValue: newM.color,
        );
        if (isLow) hasLowStockAlert = true;
      }

      await widget.vm.saveRecord(PrintRecord(
        id: widget.record?.id ?? 0,
        pieceType: name.text.trim(),
        figureCategory: finalCategory,
        date: selectedDate.millisecondsSinceEpoch,
        materials: result,
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
        cantidad: cantidad,
      ));

      if (!mounted) return;
      if (hasLowStockAlert) {
        toast(
          context,
          'Registro guardado ($cantidad ${cantidad == 1 ? 'pieza' : 'piezas'}). ¡Alerta: filamento con stock bajo (≤ 20%)!',
          isError: true,
        );
      } else {
        toast(context,
            'Registro guardado ($cantidad ${cantidad == 1 ? 'pieza' : 'piezas'}) y filamento descontado');
      }
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}


class _MaterialForm {
  String type, customType, colorName;
  final TextEditingController grams;
  int? color;
  bool combine;
  _MaterialForm(
    this.type,
    String gramsText,
    this.color,
    this.colorName,
    this.combine, {
    this.customType = '',
  }) : grams = TextEditingController(text: gramsText);
  void dispose() => grams.dispose();
}

// ==========================================
// 5. ANÁLISIS DE DATOS Y PRODUCCIÓN
// ==========================================
class AnalyticsScreen extends StatefulWidget {
  final VoidCallback? onToggleMenu;
  final VoidCallback? onHoverMenu;
  final bool isPinned;
  final PrintViewModel? vm;
  final InventoryViewModel? inventoryVm;
  const AnalyticsScreen({
    super.key,
    this.onToggleMenu,
    this.onHoverMenu,
    this.isPinned = false,
    this.vm,
    this.inventoryVm,
  });
  @override
  State<AnalyticsScreen> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<AnalyticsScreen> {
  late final PrintViewModel vm;
  bool _ownsVm = false;

  String _selectedPeriod = '6M'; // '3M', '6M', 'AÑO', 'TODO'
  String? _selectedMonthKey; // ej. '2026-AGO'
  int _metricIndex = 0; // 0 = Gramos, 1 = Piezas
  int? _hoveredBarIndex;

  @override
  void initState() {
    super.initState();
    if (widget.vm != null) {
      vm = widget.vm!;
    } else {
      vm = PrintViewModel(AppDatabase());
      _ownsVm = true;
    }
  }

  @override
  void dispose() {
    if (_ownsVm) vm.dispose();
    super.dispose();
  }

  List<PrintRecord> _getFilteredRecords() {
    final all = vm.allRecords;
    if (all.isEmpty) return [];
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case '3M':
        final threshold =
            DateTime(now.year, now.month - 2, 1).millisecondsSinceEpoch;
        return all.where((r) => r.date >= threshold).toList();
      case '6M':
        final threshold =
            DateTime(now.year, now.month - 5, 1).millisecondsSinceEpoch;
        return all.where((r) => r.date >= threshold).toList();
      case 'AÑO':
        final threshold = DateTime(now.year, 1, 1).millisecondsSinceEpoch;
        return all.where((r) => r.date >= threshold).toList();
      case 'TODO':
      default:
        return all;
    }
  }

  List<_MonthlyDataPoint> _getMonthlyPoints(List<PrintRecord> records) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, 1);

    if (records.isEmpty) {
      start = DateTime(now.year, now.month - 5, 1);
    } else {
      final sortedDates = records
          .map((r) => DateTime.fromMillisecondsSinceEpoch(r.date))
          .toList()
        ..sort();
      final earliest = sortedDates.first;
      final latest = sortedDates.last;
      start = DateTime(earliest.year, earliest.month, 1);
      final latestMonth = DateTime(latest.year, latest.month, 1);
      if (latestMonth.isAfter(end)) end = latestMonth;

      final monthDiff =
          (end.year - start.year) * 12 + end.month - start.month;
      if (_selectedPeriod == '3M' && monthDiff < 2) {
        start = DateTime(end.year, end.month - 2, 1);
      } else if (_selectedPeriod == '6M' && monthDiff < 5) {
        start = DateTime(end.year, end.month - 5, 1);
      } else if (_selectedPeriod == 'AÑO') {
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 1);
      } else if (monthDiff < 5) {
        start = DateTime(end.year, end.month - 5, 1);
      }
    }

    final grouped = <String, List<PrintRecord>>{};
    for (final record in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(record.date);
      final key = '${date.year}-${date.month}';
      grouped.putIfAbsent(key, () => []).add(record);
    }

    final points = <_MonthlyDataPoint>[];
    var cur = DateTime(start.year, start.month, 1);
    while (!cur.isAfter(end)) {
      final key = '${cur.year}-${cur.month}';
      final inMonth = grouped[key] ?? [];
      final grams = inMonth.fold(0.0, (s, r) => s + r.totalGrams);
      final pieces = inMonth.fold(0, (s, r) => s + r.cantidad);
      points.add(_MonthlyDataPoint(
        label: _monthShort(cur.month),
        year: cur.year,
        grams: grams,
        pieces: pieces,
      ));
      cur = DateTime(cur.year, cur.month + 1, 1);
    }
    return points;
  }

  static String _monthShort(int month) => const [
        'ENE',
        'FEB',
        'MAR',
        'ABR',
        'MAY',
        'JUN',
        'JUL',
        'AGO',
        'SEP',
        'OCT',
        'NOV',
        'DIC'
      ][month - 1];

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[vm];
    if (widget.inventoryVm != null) {
      listenables.add(widget.inventoryVm!);
    }
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (_, __) {
        final periodRecords = _getFilteredRecords();
        final monthlyPoints = _getMonthlyPoints(periodRecords);

        // Si hay un mes seleccionado, filtramos los datos de detalle
        final displayedRecords = _selectedMonthKey != null
            ? periodRecords.where((r) {
                final d = DateTime.fromMillisecondsSinceEpoch(r.date);
                return '${d.year}-${_monthShort(d.month)}' == _selectedMonthKey;
              }).toList()
            : periodRecords;

        final displayedGrams =
            displayedRecords.fold(0.0, (s, r) => s + r.totalGrams);
        final displayedPieces =
            displayedRecords.fold(0, (s, r) => s + r.cantidad);
        final spoolsUsed = displayedGrams / 1000.0;

        // Stock de filamento en inventario
        final inventoryItems = widget.inventoryVm?.inventoryItems ?? [];
        final totalStockGrams =
            inventoryItems.fold(0.0, (s, i) => s + i.stockActual);
        final spoolsInStock = totalStockGrams / 1000.0;

        // Desglose de materiales, colores, categorías y piezas
        final materialMap = <String, double>{};
        final colorMap = <String, double>{};
        final categoryMap = <String, double>{};
        final pieceMap = <String, _TopPieceStat>{};

        for (final r in displayedRecords) {
          final cat = r.figureCategory.trim().isEmpty
              ? 'General'
              : r.figureCategory.trim();
          categoryMap[cat] = (categoryMap[cat] ?? 0.0) + r.totalGrams;

          final pieceKey =
              r.pieceType.trim().isEmpty ? 'Sin Nombre' : r.pieceType.trim();
          final existing = pieceMap[pieceKey];
          if (existing == null) {
            pieceMap[pieceKey] = _TopPieceStat(
              name: pieceKey,
              totalGrams: r.totalGrams,
              totalUnits: r.cantidad,
              printCount: 1,
            );
          } else {
            pieceMap[pieceKey] = _TopPieceStat(
              name: pieceKey,
              totalGrams: existing.totalGrams + r.totalGrams,
              totalUnits: existing.totalUnits + r.cantidad,
              printCount: existing.printCount + 1,
            );
          }

          for (final m in r.materials) {
            final matKey = m.type.trim().toUpperCase();
            materialMap[matKey] =
                (materialMap[matKey] ?? 0.0) + (m.grams * r.cantidad);

            final colObj =
                findVoxelColor(value: m.color, name: m.colorName);
            colorMap[colObj.name] =
                (colorMap[colObj.name] ?? 0.0) + (m.grams * r.cantidad);
          }
        }

        final topPieces = pieceMap.values.toList()
          ..sort((a, b) => b.totalGrams.compareTo(a.totalGrams));

        final lotAvg = displayedRecords.isEmpty
            ? 0.0
            : (displayedPieces / displayedRecords.length);

        return Scaffold(
          appBar: darkAppBar(
            'ANÁLISIS DE PRODUCCIÓN',
            widget.onToggleMenu ?? () => goBack(context),
            leadingWidget: widget.onToggleMenu != null
                ? const SidebarToggleIcon()
                : null,
            leadingIcon: Icons.arrow_back,
            onHoverEnter: widget.onHoverMenu,
            hideLeading: widget.isPinned,
            actions: [
              // Selector de Periodo compacto y elegante
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _periodButton('3M', '3 Meses'),
                    _periodButton('6M', '6 Meses'),
                    _periodButton('AÑO', 'Este Año'),
                    _periodButton('TODO', 'Histórico'),
                  ],
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
          backgroundColor: bgBase,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // 1. CARDS OPERATIVAS COMPACTAS (Carretes, Modelos y Stock)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 700;
                      final cardWidth = isNarrow
                          ? (constraints.maxWidth - 12) / 2
                          : (constraints.maxWidth - 36) / 4;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _kpiCard(
                              title: 'CARRETES CONSUMIDOS',
                              value: '${spoolsUsed.toStringAsFixed(1)} carretes',
                              icon: Icons.album_outlined,
                              iconColor: accentPetrol,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _kpiCard(
                              title: 'MODELOS ÚNICOS',
                              value: '${pieceMap.length} diseños',
                              icon: Icons.view_in_ar_rounded,
                              iconColor: const Color(0xFF0071E3),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _kpiCard(
                              title: 'PROMEDIO POR LOTE',
                              value: '${lotAvg.toStringAsFixed(1)} uds/orden',
                              icon: Icons.layers_rounded,
                              iconColor: const Color(0xFFFF9500),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _kpiCard(
                              title: 'CARRETES EN STOCK',
                              value: widget.inventoryVm != null
                                  ? '${spoolsInStock.toStringAsFixed(1)} disp.'
                                  : 'N/A',
                              icon: Icons.inventory_2_rounded,
                              iconColor: const Color(0xFF5856D6),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // 2. SECCIÓN PRINCIPAL: GRÁFICA INTELIGENTE + CATEGORÍAS
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSingleColumn = constraints.maxWidth < 950;
                      if (isSingleColumn) {
                        return Column(
                          children: [
                            _buildEvolutionCard(monthlyPoints),
                            const SizedBox(height: 16),
                            _buildCategoryCard(categoryMap, displayedGrams),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildEvolutionCard(monthlyPoints),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child:
                                _buildCategoryCard(categoryMap, displayedGrams),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // 3. SECCIÓN SECUNDARIA: TOP PIEZAS + DESGLOSE CROMÁTICO
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSingleColumn = constraints.maxWidth < 950;
                      if (isSingleColumn) {
                        return Column(
                          children: [
                            _buildTopPiecesCard(topPieces, displayedGrams),
                            const SizedBox(height: 16),
                            _buildMaterialAndColorCard(
                              materialMap,
                              colorMap,
                              displayedGrams,
                              inventoryItems,
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child:
                                _buildTopPiecesCard(topPieces, displayedGrams),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: _buildMaterialAndColorCard(
                              materialMap,
                              colorMap,
                              displayedGrams,
                              inventoryItems,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- BOTÓN DE PERIODO EN APP BAR ---
  Widget _periodButton(String code, String tooltip) {
    final isSelected = _selectedPeriod == code;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() {
          _selectedPeriod = code;
          _selectedMonthKey = null;
        }),
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? surfaceCard : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            code,
            style: TextStyle(
              color: isSelected ? textPrimary : textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // --- TARJETA DE KPI ---
  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- TARJETA 1: EVOLUCIÓN TEMPORAL UNIFICADA ---
  Widget _buildEvolutionCard(List<_MonthlyDataPoint> points) {
    final values = _metricIndex == 0
        ? points.map((p) => p.grams).toList()
        : points.map((p) => p.pieces.toDouble()).toList();

    final maxVal =
        values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final totalVal = values.fold(0.0, (s, v) => s + v);
    final activeMonths = values.where((v) => v > 0).length;
    final avgVal =
        activeMonths > 0 ? (totalVal / activeMonths) : 0.0;

    final unitLabel = _metricIndex == 0 ? 'g' : 'piezas';
    final accent = _metricIndex == 0 ? chartPrimary : const Color(0xFF0071E3);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera con selector de métrica
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'TENDENCIA DE FABRICACIÓN',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              // Selector Toggle Gramos / Piezas
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _metricToggleOption(
                      title: 'Gramos',
                      index: 0,
                      icon: Icons.layers_outlined,
                    ),
                    _metricToggleOption(
                      title: 'Piezas',
                      index: 1,
                      icon: Icons.view_in_ar_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Badge con Promedio y Total + Indicador de Mes Filtrado
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Total: ${totalVal.toStringAsFixed(_metricIndex == 0 ? 1 : 0)} $unitLabel',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '· Media activa: ${avgVal.toStringAsFixed(1)} $unitLabel/mes',
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_selectedMonthKey != null) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => setState(() => _selectedMonthKey = null),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentPetrol.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accentPetrol.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mes: $_selectedMonthKey',
                          style: const TextStyle(
                            color: accentPetrol,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.close, size: 12, color: accentPetrol),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // Gráfica de Barras estilizada
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Eje Y (Escala de valores)
                SizedBox(
                  width: 44,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(5, (i) {
                      final val = maxVal * (4 - i) / 4;
                      return Text(
                        val >= 1000
                            ? '${(val / 1000).toStringAsFixed(1)}k'
                            : val.toStringAsFixed(val % 1 == 0 ? 0 : 1),
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 12),

                // Contenedor de Barras
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final count = points.isEmpty ? 1 : points.length;
                      final barWidth =
                          (constraints.maxWidth / count * 0.55).clamp(24.0, 48.0);
                      final chartH = constraints.maxHeight - 26;

                      // Posición de la línea de promedio
                      final avgRatio =
                          maxVal > 0 ? (avgVal / maxVal).clamp(0.0, 1.0) : 0.0;
                      final avgTop = chartH * (1.0 - avgRatio) + 4;

                      return Stack(
                        children: [
                          // Líneas de fondo sutiles
                          ...List.generate(5, (i) {
                            final top = i * chartH / 4 + 4;
                            return Positioned(
                              left: 0,
                              right: 0,
                              top: top,
                              child: Container(
                                height: 1,
                                color: borderSubtle,
                              ),
                            );
                          }),

                          // Línea guía de promedio mensual
                          if (avgVal > 0)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: avgTop,
                              child: Container(
                                height: 1.2,
                                color: accent.withValues(alpha: 0.35),
                              ),
                            ),

                          // Barras interactivas
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: points.asMap().entries.map((e) {
                                final idx = e.key;
                                final point = e.value;
                                final pointKey = '${point.year}-${point.label}';
                                final isSelectedMonth =
                                    _selectedMonthKey == pointKey;
                                final val = _metricIndex == 0
                                    ? point.grams
                                    : point.pieces.toDouble();
                                final isZero = val == 0;
                                final ratio = isZero
                                    ? 0.02
                                    : (val / (maxVal == 0 ? 1 : maxVal))
                                        .clamp(0.04, 1.0);
                                final isHovered = _hoveredBarIndex == idx;

                                return Expanded(
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    onEnter: (_) => setState(
                                        () => _hoveredBarIndex = idx),
                                    onExit: (_) => setState(
                                        () => _hoveredBarIndex = null),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        setState(() {
                                          if (_selectedMonthKey == pointKey) {
                                            _selectedMonthKey = null;
                                          } else {
                                            _selectedMonthKey = pointKey;
                                          }
                                        });
                                      },
                                      child: Tooltip(
                                        waitDuration:
                                            const Duration(milliseconds: 100),
                                        message:
                                            '${point.label} ${point.year}\n• ${point.grams.toStringAsFixed(1)} g\n• ${point.pieces} piezas\n(Clic para filtrar)',
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 150),
                                                  width: barWidth,
                                                  height: chartH * ratio,
                                                  decoration: BoxDecoration(
                                                    color: isZero
                                                        ? borderSubtle
                                                            .withValues(alpha: 0.5)
                                                        : (isSelectedMonth
                                                            ? const Color(0xFF0071E3)
                                                            : (isHovered
                                                                ? accentPetrolHover
                                                                : accent)),
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                      top: Radius.circular(5),
                                                    ),
                                                    border: isSelectedMonth
                                                        ? Border.all(
                                                            color: Colors.white
                                                                .withValues(alpha: 0.9),
                                                            width: 1.5,
                                                          )
                                                        : null,
                                                    boxShadow: (isHovered || isSelectedMonth) && !isZero
                                                        ? [
                                                            BoxShadow(
                                                              color: (isSelectedMonth
                                                                      ? const Color(0xFF0071E3)
                                                                      : accent)
                                                                  .withValues(
                                                                      alpha: 0.4),
                                                              blurRadius: 8,
                                                              offset: const Offset(
                                                                  0, -2),
                                                            )
                                                          ]
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: isSelectedMonth
                                                  ? const EdgeInsets.symmetric(horizontal: 5, vertical: 1)
                                                  : EdgeInsets.zero,
                                              decoration: isSelectedMonth
                                                  ? BoxDecoration(
                                                      color: const Color(0xFF0071E3).withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(4),
                                                    )
                                                  : null,
                                              child: Text(
                                                point.label,
                                                style: TextStyle(
                                                  color: isSelectedMonth
                                                      ? const Color(0xFF0071E3)
                                                      : (isHovered
                                                          ? textPrimary
                                                          : (isZero
                                                              ? textMuted
                                                              : textSecondary)),
                                                  fontSize: 10,
                                                  fontWeight: (isHovered || isSelectedMonth)
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricToggleOption({
    required String title,
    required int index,
    required IconData icon,
  }) {
    final isSelected = _metricIndex == index;
    return InkWell(
      onTap: () => setState(() => _metricIndex = index),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? surfaceCard : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? accentPetrol : textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? textPrimary : textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TARJETA 2: DISTRIBUCIÓN POR CATEGORÍA ---
  Widget _buildCategoryCard(Map<String, double> categories, double totalGrams) {
    final entries = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const categoryColors = [
      Color(0xFF0066CC), // Petrol
      Color(0xFF5856D6), // Indigo
      Color(0xFF30B0C7), // Teal
      Color(0xFFFF9500), // Amber
      Color(0xFF34C759), // Green
      Color(0xFFFF2D55), // Red
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CATEGORÍAS DE USO',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderSubtle),
                ),
                child: Text(
                  '${entries.length} tipos',
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No hay categorías registradas',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ),
            )
          else
            Column(
              children: entries.asMap().entries.map((e) {
                final idx = e.key;
                final entry = e.value;
                final pct =
                    totalGrams > 0 ? (entry.value / totalGrams) : 0.0;
                final col = categoryColors[idx % categoryColors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                color: textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${entry.value.toStringAsFixed(1)} g',
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${(pct * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.01, 1.0),
                          minHeight: 5,
                          backgroundColor: surfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(col),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- TARJETA 3: TOP 5 PIEZAS CON MAYOR CONSUMO ---
  Widget _buildTopPiecesCard(List<_TopPieceStat> topPieces, double totalGrams) {
    final highestGrams =
        topPieces.isEmpty ? 1.0 : topPieces.first.totalGrams;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IMPRESIONES CON MAYOR CONSUMO',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(Icons.leaderboard_outlined,
                  size: 16, color: accentPetrol),
            ],
          ),
          const SizedBox(height: 16),
          if (topPieces.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No hay piezas registradas en el periodo',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ),
            )
          else
            Column(
              children: topPieces.asMap().entries.map((e) {
                final rank = e.key + 1;
                final piece = e.value;
                final ratio = highestGrams > 0
                    ? (piece.totalGrams / highestGrams).clamp(0.01, 1.0)
                    : 0.0;

                final Color medalColor = rank == 1
                    ? const Color(0xFFFF9500)
                    : (rank == 2
                        ? const Color(0xFF8E8E93)
                        : (rank == 3
                            ? const Color(0xFFC97A3E)
                            : textMuted));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Posición del ranking
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rank <= 3
                              ? medalColor.withValues(alpha: 0.15)
                              : surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            color: rank <= 3 ? medalColor : textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Nombre y detalles
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${piece.name} · ${piece.totalUnits} uds',
                              style: const TextStyle(
                                color: textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 4,
                                backgroundColor: surfaceElevated,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        accentPetrol),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Gramos acumulados
                      Text(
                        '${piece.totalGrams.toStringAsFixed(1)} g',
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- TARJETA 4: MATERIALES Y COLORES DE FILAMENTO ---
  Widget _buildMaterialAndColorCard(
    Map<String, double> materials,
    Map<String, double> colors,
    double totalGrams,
    List<InventoryItem> inventoryItems,
  ) {
    final matEntries = materials.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colEntries = colors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MATERIALES Y COLORES',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(Icons.palette_outlined, size: 16, color: accentAmber),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Tarjetas Compactas de Tipo de Material
          const Text(
            'TIPOS DE FILAMENTO',
            style: TextStyle(
              color: textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          if (matEntries.isEmpty)
            const Text('Sin datos',
                style: TextStyle(color: textSecondary, fontSize: 11))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: matEntries.map((m) {
                final pct = totalGrams > 0 ? (m.value / totalGrams) : 0.0;
                final stockGrams = inventoryItems
                    .where((i) =>
                        i.material.trim().toUpperCase() ==
                        m.key.trim().toUpperCase())
                    .fold(0.0, (s, i) => s + i.stockActual);

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: accentPetrol.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          m.key,
                          style: const TextStyle(
                            color: accentPetrol,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${m.value.toStringAsFixed(1)} g',
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${(pct * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (inventoryItems.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: stockGrams > 0
                                ? surfaceCard
                                : const Color(0xFFFF9500).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: stockGrams > 0
                                  ? borderSubtle
                                  : const Color(0xFFFF9500).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            stockGrams > 0
                                ? 'Stock: ${stockGrams >= 1000 ? '${(stockGrams / 1000).toStringAsFixed(1)} kg' : '${stockGrams.toInt()} g'}'
                                : 'Sin stock',
                            style: TextStyle(
                              color: stockGrams > 0
                                  ? textSecondary
                                  : const Color(0xFFFF9500),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 16),
          const Divider(color: borderSubtle, height: 1),
          const SizedBox(height: 14),

          // 2. Chips Cromáticos de Colores
          const Text(
            'COLORES MÁS UTILIZADOS',
            style: TextStyle(
              color: textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          if (colEntries.isEmpty)
            const Text('Sin datos',
                style: TextStyle(color: textSecondary, fontSize: 11))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colEntries.map((c) {
                final colObj = findVoxelColor(name: c.key);
                final pct = totalGrams > 0 ? (c.value / totalGrams) : 0.0;

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      colorSwatchCircle(
                        colObj.color,
                        size: 11,
                        isTransparent: colObj.isTransparent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        c.key,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${c.value.toStringAsFixed(0)} g',
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '(${(pct * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _MonthlyDataPoint {
  final String label;
  final int year;
  final double grams;
  final int pieces;

  _MonthlyDataPoint({
    required this.label,
    required this.year,
    required this.grams,
    required this.pieces,
  });
}

class _TopPieceStat {
  final String name;
  final double totalGrams;
  final int totalUnits;
  final int printCount;

  _TopPieceStat({
    required this.name,
    required this.totalGrams,
    required this.totalUnits,
    required this.printCount,
  });
}

// ==========================================
// 6. EXPORTAR DATOS (PDF / EXCEL)
// ==========================================
class _ExportSummaryRow {
  final String label;
  final int count;
  final double grams;

  const _ExportSummaryRow({
    required this.label,
    required this.count,
    required this.grams,
  });
}

List<excel_pkg.CellValue?> _toExcelRow(List<dynamic> values) =>
    values.map((value) {
      if (value is int) return excel_pkg.IntCellValue(value);
      if (value is double) return excel_pkg.DoubleCellValue(value);
      return excel_pkg.TextCellValue(value.toString());
    }).toList();

class ExportScreen extends StatefulWidget {
  final VoidCallback? onToggleMenu;
  final VoidCallback? onHoverMenu;
  final bool isPinned;
  final PrintViewModel vm;
  final InventoryViewModel? inventoryVm;
  const ExportScreen({
    super.key,
    this.onToggleMenu,
    this.onHoverMenu,
    this.isPinned = false,
    required this.vm,
    this.inventoryVm,
  });
  @override
  State<ExportScreen> createState() => _ExportState();
}

class _ExportState extends State<ExportScreen> {
  int tab = 0; // 0 = Impresiones, 1 = Inventario
  final selectedPrint = <int>{};
  final selectedInventory = <String>{};
  late final InventoryViewModel inventory;
  bool _ownsInventory = false;
  String period = 'MES';

  Future<void> _saveBytes(List<int> bytes, String fileName, String mimeType,
      String extension) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
      await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          files: [
            share_plus.XFile.fromData(Uint8List.fromList(bytes),
                mimeType: mimeType),
          ],
          fileNameOverrides: [fileName],
          downloadFallbackEnabled: true,
        ),
      );
      return;
    }

    final location = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: [
        XTypeGroup(label: extension.toUpperCase(), extensions: [extension]),
      ],
    );
    if (location == null) return;
    await XFile.fromData(Uint8List.fromList(bytes),
            name: fileName, mimeType: mimeType)
        .saveTo(location.path);
  }

  @override
  void initState() {
    super.initState();
    if (widget.inventoryVm != null) {
      inventory = widget.inventoryVm!;
    } else {
      inventory = InventoryViewModel(AppDatabase());
      _ownsInventory = true;
    }
    inventory.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    inventory.removeListener(_refresh);
    if (_ownsInventory) inventory.dispose();
    super.dispose();
  }

  List<PrintRecord> get _availablePrints {
    final all = widget.vm.allRecords;
    if (selectedPrint.isEmpty) return all;
    return all.where((record) => selectedPrint.contains(record.id)).toList();
  }

  List<InventoryItem> get _availableInventory {
    final all = inventory.inventoryItems;
    if (selectedInventory.isEmpty) return all;
    return all.where((item) => selectedInventory.contains(item.id)).toList();
  }

  String _monthName(int month) => const [
        'ENE',
        'FEB',
        'MAR',
        'ABR',
        'MAY',
        'JUN',
        'JUL',
        'AGO',
        'SEP',
        'OCT',
        'NOV',
        'DIC'
      ][month - 1];

  List<_ExportSummaryRow> _buildSummaryRows(List<PrintRecord> records) {
    final grouped = <DateTime, double>{};
    final counts = <DateTime, int>{};

    for (final record in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(record.date);
      final bucket = switch (period) {
        'DÍA' => DateTime(date.year, date.month, date.day),
        'SEMANA' => date.subtract(Duration(days: date.weekday - 1)),
        _ => DateTime(date.year, date.month, 1),
      };

      grouped[bucket] = (grouped[bucket] ?? 0) + record.totalGrams;
      counts[bucket] = (counts[bucket] ?? 0) + record.cantidad;
    }

    final ordered = grouped.keys.toList()..sort();
    return ordered.map((date) {
      final end = period == 'SEMANA' ? date.add(const Duration(days: 6)) : date;
      final label = switch (period) {
        'DÍA' =>
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
        'SEMANA' =>
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}',
        _ => '${_monthName(date.month)} ${date.year}',
      };

      return _ExportSummaryRow(
        label: label,
        count: counts[date] ?? 0,
        grams: grouped[date] ?? 0,
      );
    }).toList();
  }

  String _getPeriodExplanation(String p) {
    final now = DateTime.now();
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return switch (p) {
      'DÍA' => 'Hoy: ${fmt(now)} (últimas 24 horas)',
      'SEMANA' =>
        'Esta semana: del ${fmt(now.subtract(const Duration(days: 7)))} al ${fmt(now)} (últimos 7 días)',
      'MES' =>
        'Este mes: del ${fmt(DateTime(now.year, now.month, 1))} al ${fmt(now)}',
      _ => 'Periodo seleccionado',
    };
  }

  Future<void> _savePdf(
    List<_ExportSummaryRow> summaryRows,
    List<PrintRecord> prints,
    String title,
  ) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generado el ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} · Total registros seleccionados: ${prints.length}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 14),

          pw.Text('RESUMEN POR PERIODO',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['PERIODO', 'PIEZAS TOTALES', 'CONSUMO TOTAL'],
            data: summaryRows
                .map((row) => [
                      row.label,
                      row.count.toString(),
                      '${row.grams.toStringAsFixed(1)} g'
                    ])
                .toList(),
            border: null,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          ),
          pw.SizedBox(height: 16),

          pw.Text('DETALLE DE PIEZAS FABRICADAS',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: [
              'FECHA',
              'PIEZA',
              'MATERIAL / COLOR',
              'CANTIDAD',
              'GRAMOS C/U',
              'TOTAL GRAMOS'
            ],
            data: prints.map((r) {
              final matStr = r.materials.map((m) {
                final cName = (m.colorName != null && m.colorName!.trim().isNotEmpty)
                    ? m.colorName!
                    : findVoxelColor(value: m.color).name;
                return '${m.type} ($cName)';
              }).join(', ');
              final date = DateTime.fromMillisecondsSinceEpoch(r.date);
              final dateStr =
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
              return [
                dateStr,
                r.pieceType,
                matStr,
                '${r.cantidad}',
                '${r.unitGrams.toStringAsFixed(1)} g',
                '${r.totalGrams.toStringAsFixed(1)} g',
              ];
            }).toList(),
            border: null,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final fileName =
        'voxelcost3d_${period.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await _saveBytes(bytes, fileName, 'application/pdf', 'pdf');
  }

  Future<void> _saveExcel(
    List<_ExportSummaryRow> summaryRows,
    List<PrintRecord> prints,
    String title,
  ) async {
    final excel = excel_pkg.Excel.createExcel();
    final sheetSummary = excel['Resumen'];
    sheetSummary.appendRow(_toExcelRow(['TITULO', title]));
    sheetSummary.appendRow(_toExcelRow(['PERIODO', 'PIEZAS TOTALES', 'CONSUMO TOTAL']));
    for (final row in summaryRows) {
      sheetSummary.appendRow(_toExcelRow(
          [row.label, row.count, '${row.grams.toStringAsFixed(1)} g']));
    }

    final sheetDetail = excel['Detalle Impresiones'];
    sheetDetail.appendRow(_toExcelRow([
      'FECHA',
      'PIEZA',
      'CATEGORÍA',
      'MATERIAL Y COLOR',
      'CANTIDAD',
      'GRAMOS POR UNIDAD',
      'GRAMOS TOTALES',
      'OBSERVACIONES'
    ]));
    for (final r in prints) {
      final matStr = r.materials.map((m) {
        final cName = (m.colorName != null && m.colorName!.trim().isNotEmpty)
            ? m.colorName!
            : findVoxelColor(value: m.color).name;
        return '${m.type} ($cName)';
      }).join(', ');
      final date = DateTime.fromMillisecondsSinceEpoch(r.date);
      final dateStr =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      sheetDetail.appendRow(_toExcelRow([
        dateStr,
        r.pieceType,
        r.figureCategory,
        matStr,
        r.cantidad,
        '${r.unitGrams.toStringAsFixed(1)} g',
        '${r.totalGrams.toStringAsFixed(1)} g',
        r.notes ?? ''
      ]));
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('No se pudo serializar el archivo Excel');
    }

    final fileName =
        'voxelcost3d_${period.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await _saveBytes(
        bytes,
        fileName,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'xlsx');
  }

  Future<void> _saveInventoryPdf(List<List<String>> rows) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Text(
            'VOXELCOST3D - INVENTARIO DE MATERIALES',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['MATERIAL', 'STOCK ACTUAL', 'STOCK INICIAL'],
            data: rows,
            border: null,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final fileName =
        'voxelcost3d_inventario_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await _saveBytes(bytes, fileName, 'application/pdf', 'pdf');
  }

  Future<void> _saveInventoryExcel(List<List<String>> rows) async {
    final excel = excel_pkg.Excel.createExcel();
    final sheet = excel['Inventario'];
    sheet.appendRow(_toExcelRow(['PRODUCTO', 'STOCK ACTUAL', 'STOCK INICIAL']));
    for (final row in rows) {
      sheet.appendRow(_toExcelRow(row));
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('No se pudo serializar el archivo Excel');
    }

    final fileName =
        'voxelcost3d_inventario_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await _saveBytes(
        bytes,
        fileName,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'xlsx');
  }

  Future<void> _export(BuildContext context, String format, int count) async {
    if (count == 0) {
      toast(context, 'Selecciona al menos un registro para exportar',
          isError: true);
      return;
    }

    try {
      if (tab == 0) {
        final rows = _buildSummaryRows(_availablePrints);
        if (format == 'PDF') {
          await _savePdf(
              rows, _availablePrints, 'VOXELCOST3D - REPORTE DE PRODUCCIÓN (${period.toUpperCase()})');
        } else {
          await _saveExcel(
              rows, _availablePrints, 'VOXELCOST3D - REPORTE DE PRODUCCIÓN (${period.toUpperCase()})');
        }
      } else {
        final rows = _availableInventory
            .map((item) => [
                  '${item.material} (${item.color})',
                  '${item.stockActual.toStringAsFixed(1)} g',
                  '${item.stockInicial.toStringAsFixed(1)} g',
                ])
            .toList();
        if (format == 'PDF') {
          await _saveInventoryPdf(rows);
        } else {
          await _saveInventoryExcel(rows);
        }
      }
      if (!context.mounted) return;
      toast(context, 'Archivo $format exportado correctamente');
    } catch (_) {
      if (!context.mounted) return;
      toast(context, 'Error al generar el archivo $format', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = tab == 0 ? selectedPrint.length : selectedInventory.length;
    final totalItems = tab == 0
        ? widget.vm.allRecords.length
        : inventory.inventoryItems.length;

    return Scaffold(
      appBar: darkAppBar(
        'EXPORTAR DATOS',
        widget.onToggleMenu ?? () => goBack(context),
        leadingWidget: widget.onToggleMenu != null
            ? const SidebarToggleIcon()
            : null,
        leadingIcon: Icons.arrow_back,
        onHoverEnter: widget.onHoverMenu,
        hideLeading: widget.isPinned,
      ),
      backgroundColor: bgBase,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: Column(
            children: [
              // Segmented Control Tabs
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabButton('IMPRESIONES', 0, Icons.layers_outlined),
                    ),
                    Expanded(
                      child: _tabButton(
                          'INVENTARIO', 1, Icons.inventory_2_outlined),
                    ),
                  ],
                ),
              ),

              // Filter & Selection Toolbar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (tab == 0) {
                            if (selectedPrint.length ==
                                widget.vm.allRecords.length) {
                              selectedPrint.clear();
                            } else {
                              selectedPrint.clear();
                              selectedPrint.addAll(widget.vm.allRecords
                                  .map((record) => record.id));
                            }
                          } else {
                            if (selectedInventory.length ==
                                inventory.inventoryItems.length) {
                              selectedInventory.clear();
                            } else {
                              selectedInventory.clear();
                              selectedInventory.addAll(inventory
                                  .inventoryItems
                                  .map((item) => item.id));
                            }
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (count == totalItems && totalItems > 0)
                                ? Icons.check_box
                                : (count > 0
                                    ? Icons.indeterminate_check_box
                                    : Icons.check_box_outline_blank),
                            size: 18,
                            color: count > 0 ? accentPetrol : textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SELECCIONAR TODOS ($count/$totalItems)',
                            style: TextStyle(
                              color: count > 0 ? textPrimary : textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (tab == 0) ...[
                      const Text(
                        'PERIODO:',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: DropdownButton<String>(
                          value: period,
                          underline: const SizedBox(),
                          dropdownColor: surfaceElevated,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: textSecondary, size: 18),
                          items: const [
                            DropdownMenuItem(value: 'DÍA', child: Text('DÍA')),
                            DropdownMenuItem(
                                value: 'SEMANA', child: Text('SEMANA')),
                            DropdownMenuItem(value: 'MES', child: Text('MES')),
                          ],
                          onChanged: (value) =>
                              setState(() => period = value ?? 'MES'),
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (tab == 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16)
                      .copyWith(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: surfaceElevated.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: borderSubtle.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 13, color: textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Rango activo: ${_getPeriodExplanation(period)}',
                        style: const TextStyle(
                            color: textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),

              // Items Grid with Rich Preview Cards
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 600
                          ? 2
                          : 1;

                  if (tab == 0) {
                    if (widget.vm.allRecords.isEmpty) {
                      return const Center(
                        child: Text('No hay registros de impresión',
                            style: TextStyle(color: textSecondary)),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: columns == 1 ? 3.0 : 2.0,
                      ),
                      itemCount: widget.vm.allRecords.length,
                      itemBuilder: (_, index) {
                        final r = widget.vm.allRecords[index];
                        final checked = selectedPrint.contains(r.id);
                        final totalGrams = r.totalGrams;
                        return _printPreviewCard(r, checked, totalGrams);
                      },
                    );
                  } else {
                    if (inventory.inventoryItems.isEmpty) {
                      return const Center(
                        child: Text('No hay materiales en el inventario',
                            style: TextStyle(color: textSecondary)),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: columns == 1 ? 3.4 : 2.2,
                      ),
                      itemCount: inventory.inventoryItems.length,
                      itemBuilder: (_, index) {
                        final item = inventory.inventoryItems[index];
                        final checked = selectedInventory.contains(item.id);
                        return _inventoryPreviewCard(item, checked);
                      },
                    );
                  }
                }),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: surfaceCard,
                  border: Border(top: BorderSide(color: borderSubtle)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: techButton(
                        'EXPORTAR PDF ($count)',
                        () => _export(context, 'PDF', count),
                        icon: Icons.picture_as_pdf_outlined,
                        color: surfaceElevated,
                        foreground: textPrimary,
                        isOutlined: true,
                        height: 44,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: techButton(
                        'EXPORTAR EXCEL ($count)',
                        () => _export(context, 'Excel', count),
                        icon: Icons.table_chart_outlined,
                        color: accentPetrol,
                        foreground: textPrimary,
                        height: 44,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String title, int targetTab, IconData icon) {
    final active = tab == targetTab;
    return InkWell(
      onTap: () => setState(() => tab = targetTab),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: borderSubtle) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? accentPetrol : textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: active ? textPrimary : textSecondary,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _printPreviewCard(
      PrintRecord r, bool checked, double totalGrams) =>
      InkWell(
        onTap: () => setState(() {
          if (checked) {
            selectedPrint.remove(r.id);
          } else {
            selectedPrint.add(r.id);
          }
        }),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: checked
                ? accentPetrol.withValues(alpha: 0.08)
                : surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: checked ? accentPetrol : borderSubtle,
              width: checked ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                checked ? Icons.check_box : Icons.check_box_outline_blank,
                size: 18,
                color: checked ? accentPetrol : textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.pieceType,
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${r.figureCategory.toUpperCase()} · ${dateText(r.date, short: true)}',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (r.cantidad > 1) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: accentAmber.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: accentAmber.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              '×${r.cantidad}',
                              style: const TextStyle(
                                color: accentAmber,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: r.materials.take(2).map((m) {
                              final colorObj =
                                  findVoxelColor(value: m.color);
                              final colName = (m.colorName != null &&
                                      m.colorName!.trim().isNotEmpty)
                                  ? m.colorName!
                                  : colorObj.name;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  colorSwatchCircle(colorObj.color,
                                      size: 8,
                                      isTransparent: colorObj.isTransparent),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${m.type} · $colName',
                                    style: const TextStyle(
                                      color: textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            r.cantidad > 1
                                ? '${r.totalGrams.toStringAsFixed(1)} g (${r.unitGrams.toStringAsFixed(1)}g c/u)'
                                : '${r.totalGrams.toStringAsFixed(1)} g',
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _inventoryPreviewCard(InventoryItem item, bool checked) {
    final ratio = item.stockInicial > 0
        ? (item.stockActual / item.stockInicial).clamp(0.0, 1.0)
        : 0.0;
    final isLow = item.stockInicial <= 0 || ratio <= 0.2;

    return InkWell(
      onTap: () => setState(() {
        if (checked) {
          selectedInventory.remove(item.id);
        } else {
          selectedInventory.add(item.id);
        }
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: checked
              ? accentPetrol.withValues(alpha: 0.08)
              : surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: checked ? accentPetrol : borderSubtle,
            width: checked ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: checked ? accentPetrol : textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      colorSwatchCircle(parseHex(item.colorHex), size: 10),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${item.material} - ${item.color}',
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 4,
                          backgroundColor: surfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isLow ? semanticDanger : accentPetrol,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.stockActual.toInt()} g disp.',
                            style: TextStyle(
                              color: isLow ? semanticDanger : textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(ratio * 100).toInt()}%',
                            style: const TextStyle(
                              color: textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. INVENTARIO DE MATERIALES
// ==========================================
class InventoryScreen extends StatefulWidget {
  final VoidCallback? onToggleMenu;
  final VoidCallback? onHoverMenu;
  final bool isPinned;
  final InventoryViewModel? vm;
  const InventoryScreen({
    super.key,
    this.onToggleMenu,
    this.onHoverMenu,
    this.isPinned = false,
    this.vm,
  });
  @override
  State<InventoryScreen> createState() => _InventoryState();
}

class _InventoryState extends State<InventoryScreen> {
  late final InventoryViewModel vm;
  bool _ownsVm = false;
  String search = '';
  String statusFilter = 'Todos'; // 'Todos', 'Activos', 'Bajo', 'Agotados'
  String materialFilter = 'Todos';
  String brandFilter = 'Todas';
  bool isGridView = true;

  @override
  void initState() {
    super.initState();
    if (widget.vm != null) {
      vm = widget.vm!;
    } else {
      vm = InventoryViewModel(AppDatabase());
      _ownsVm = true;
    }
  }

  @override
  void dispose() {
    if (_ownsVm) vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: vm,
        builder: (_, __) {
          final items = vm.inventoryItems.where((i) {
            // Filtro de búsqueda
            if (search.trim().isNotEmpty) {
              final q = search.trim().toLowerCase();
              final match = i.material.toLowerCase().contains(q) ||
                  i.color.toLowerCase().contains(q) ||
                  i.brand.toLowerCase().contains(q) ||
                  i.finish.toLowerCase().contains(q) ||
                  (i.location?.toLowerCase().contains(q) ?? false) ||
                  (i.notes?.toLowerCase().contains(q) ?? false);
              if (!match) return false;
            }

            // Filtro por Estado
            if (statusFilter == 'Activos' && i.isDepleted) return false;
            if (statusFilter == 'Bajo' && !i.isLowStock) return false;
            if (statusFilter == 'Agotados' && !i.isDepleted) return false;

            // Filtro por Material
            if (materialFilter != 'Todos' && i.material != materialFilter) {
              return false;
            }

            // Filtro por Marca
            if (brandFilter != 'Todas' && i.brand != brandFilter) {
              return false;
            }

            return true;
          }).toList();

          return Scaffold(
            appBar: darkAppBar(
              'INVENTARIO DE MATERIALES',
              widget.onToggleMenu ?? () => goBack(context),
              leadingWidget: widget.onToggleMenu != null
                  ? const SidebarToggleIcon()
                  : null,
              leadingIcon: Icons.arrow_back,
              onHoverEnter: widget.onHoverMenu,
              hideLeading: widget.isPinned,
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddProductScreen(vm: vm),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 16, color: textPrimary),
                    label: const Text('Nueva Bobina',
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 0),
                      backgroundColor: accentPetrol,
                      foregroundColor: textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            backgroundColor: bgBase,
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: double.infinity),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barra de Control Minimalista (Buscador + Filtros + Vista)
                      Row(
                        children: [
                          // Buscador compacto
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                onChanged: (x) => setState(() => search = x),
                                style: const TextStyle(
                                    color: textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Buscar material, color o marca...',
                                  hintStyle: const TextStyle(
                                      color: textMuted, fontSize: 13),
                                  prefixIcon: const Icon(Icons.search,
                                      color: textSecondary, size: 17),
                                  suffixIcon: search.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear,
                                              size: 14, color: textSecondary),
                                          onPressed: () =>
                                              setState(() => search = ''),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: surfaceCard,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        const BorderSide(color: borderSubtle),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        const BorderSide(color: borderSubtle),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: accentPetrol, width: 1.2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Filtros de Estado Compactos
                          _filterChip(
                            'Todas (${vm.inventoryItems.length})',
                            statusFilter == 'Todos',
                            () => setState(() => statusFilter = 'Todos'),
                          ),
                          if (vm.lowStockCount > 0)
                            _filterChip(
                              'Bajo Stock (${vm.lowStockCount})',
                              statusFilter == 'Bajo',
                              () => setState(() => statusFilter = 'Bajo'),
                              isAlert: true,
                            ),
                          if (vm.depletedStockCount > 0)
                            _filterChip(
                              'Agotadas (${vm.depletedStockCount})',
                              statusFilter == 'Agotados',
                              () => setState(() => statusFilter = 'Agotados'),
                            ),

                          // Menú desplegable de Material (si hay variedad)
                          if (vm.inventoryItems
                                  .map((x) => x.material)
                                  .toSet()
                                  .length >
                              1) ...[
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              tooltip: 'Filtrar por material',
                              onSelected: (val) =>
                                  setState(() => materialFilter = val),
                              color: surfaceElevated,
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'Todos',
                                    child: Text('Todos los materiales')),
                                ...vm.inventoryItems
                                    .map((x) => x.material)
                                    .toSet()
                                    .map((mat) => PopupMenuItem(
                                        value: mat, child: Text(mat))),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 8),
                                decoration: BoxDecoration(
                                  color: materialFilter != 'Todos'
                                      ? accentPetrol
                                      : surfaceCard,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: materialFilter != 'Todos'
                                        ? accentPetrol
                                        : borderSubtle,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      materialFilter == 'Todos'
                                          ? 'Material'
                                          : materialFilter,
                                      style: TextStyle(
                                        color: materialFilter != 'Todos'
                                            ? textPrimary
                                            : textSecondary,
                                        fontSize: 11,
                                        fontWeight: materialFilter != 'Todos'
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.arrow_drop_down,
                                        size: 14, color: textSecondary),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Selector de Vista (Cuadrícula / Lista)
                          const SizedBox(width: 8),
                          Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: surfaceCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderSubtle),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Cuadrícula',
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  icon: Icon(Icons.grid_view_rounded,
                                      size: 16,
                                      color: isGridView
                                          ? accentPetrol
                                          : textSecondary),
                                  onPressed: () =>
                                      setState(() => isGridView = true),
                                ),
                                IconButton(
                                  tooltip: 'Lista',
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  icon: Icon(Icons.view_list_rounded,
                                      size: 16,
                                      color: !isGridView
                                          ? accentPetrol
                                          : textSecondary),
                                  onPressed: () =>
                                      setState(() => isGridView = false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (vm.error != null) ...[
                        _databaseError(vm.error!),
                        const SizedBox(height: 12),
                      ],

                      // Lista o Cuadrícula de Materiales Minimalista
                      Expanded(
                        child: items.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 40,
                                      color:
                                          textSecondary.withValues(alpha: 0.35),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      search.isNotEmpty ||
                                              statusFilter != 'Todos' ||
                                              materialFilter != 'Todos' ||
                                              brandFilter != 'Todas'
                                          ? 'No se encontraron bobinas con estos filtros'
                                          : 'No hay bobinas registradas',
                                      style: const TextStyle(
                                          color: textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              )
                            : isGridView
                                ? GridView.builder(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 360,
                                      mainAxisExtent: 154,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (_, index) =>
                                        _inventoryCard(items[index]),
                                  )
                                : _inventoryTable(items),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

  Widget _databaseError(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: semanticDanger.withValues(alpha: 0.12),
          border: Border.all(color: semanticDanger.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(message,
            style: const TextStyle(color: semanticDanger, fontSize: 12)),
      );

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap,
      {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isAlert ? semanticDanger : accentPetrol)
                : surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (isAlert ? semanticDanger : accentPetrol)
                  : borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? textPrimary : textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _inventoryCard(InventoryItem item) {
    final ratio = item.remainingRatio;
    final low = item.isLowStock;
    final depleted = item.isDepleted;
    final spoolColor = parseHex(item.colorHex);
    final hasRealBrand =
        item.brand.trim().isNotEmpty && item.brand.trim() != 'Genérica';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: depleted
              ? borderSubtle
              : low
                  ? semanticDanger.withValues(alpha: 0.5)
                  : borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Fila Superior: Swatch + Nombre/Marca + Menú (...)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              colorSwatchCircle(spoolColor, size: 14),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasRealBrand)
                      Text(
                        item.brand.toUpperCase(),
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      '${item.material} · ${item.color}',
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Alertas sutiles (SIN badge verde 'DISPONIBLE' que sature)
              if (depleted)
                _statusBadge('AGOTADO', semanticDanger)
              else if (low)
                _statusBadge('BAJO STOCK', semanticDanger),

              // Menú desplegable discreto con todas las acciones
              PopupMenuButton<String>(
                tooltip: 'Opciones',
                icon: const Icon(Icons.more_horiz_rounded,
                    size: 18, color: textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: surfaceElevated,
                onSelected: (val) async {
                  if (val == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddProductScreen(vm: vm, itemToEdit: item),
                      ),
                    );
                  } else if (val == 'weigh') {
                    _showWeighAndTareDialog(item);
                  } else if (val == 'copy') {
                    await vm.duplicateItem(item);
                    if (!mounted) return;
                    toast(context, 'Bobina duplicada con éxito');
                  } else if (val == 'delete') {
                    _confirmDeleteItem(item);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 15, color: textSecondary),
                        SizedBox(width: 8),
                        Text('Editar ficha', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'weigh',
                    child: Row(
                      children: [
                        Icon(Icons.scale_outlined,
                            size: 15, color: textSecondary),
                        SizedBox(width: 8),
                        Text('Pesar en báscula (tara)',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.copy_outlined,
                            size: 15, color: textSecondary),
                        SizedBox(width: 8),
                        Text('Duplicar bobina',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 15, color: semanticDanger),
                        SizedBox(width: 8),
                        Text('Eliminar',
                            style: TextStyle(
                                fontSize: 12, color: semanticDanger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Medidor Central de Stock (Grande, legible y limpio)
          InkWell(
            onTap: () => _showWeighAndTareDialog(item),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${item.stockActual.toInt()} g',
                            style: TextStyle(
                              color: low ? semanticDanger : textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'de ${item.stockInicial.toInt()} g',
                            style: const TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${(ratio * 100).toInt()}%',
                        style: TextStyle(
                          color: low ? semanticDanger : textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 4,
                      backgroundColor: surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        depleted
                            ? textMuted
                            : low
                                ? semanticDanger
                                : accentPetrol,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Fila Inferior: Detalles técnicos tenues + Botones de ajuste sutiles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${item.diameter.toStringAsFixed(2)} mm'
                  '${item.tempNozzle != null ? ' · ♨ ${item.tempNozzle}°C' : ''}'
                  '${item.finish != 'Estándar' && item.finish.isNotEmpty ? ' · ${item.finish}' : ''}',
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  _adjustTextButton('-50g', () => vm.updateStock(item, -50)),
                  const SizedBox(width: 4),
                  _adjustTextButton('+50g', () => vm.updateStock(item, 50)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inventoryTable(List<InventoryItem> items) => ListView.separated(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, index) {
          final item = items[index];
          final ratio = item.remainingRatio;
          final low = item.isLowStock;
          final depleted = item.isDepleted;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    low ? semanticDanger.withValues(alpha: 0.5) : borderSubtle,
              ),
            ),
            child: Row(
              children: [
                colorSwatchCircle(parseHex(item.colorHex), size: 12),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.brand != 'Genérica' ? '[${item.brand}] ' : ''}${item.material} · ${item.color}',
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.diameter.toStringAsFixed(2)} mm'
                        '${item.tempNozzle != null ? ' · ${item.tempNozzle}°C' : ''}',
                        style:
                            const TextStyle(color: textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.stockActual.toInt()} g',
                            style: TextStyle(
                              color: low ? semanticDanger : textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${(ratio * 100).toInt()}%',
                            style: TextStyle(
                              color: low ? semanticDanger : textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 3,
                          backgroundColor: surfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            depleted
                                ? textMuted
                                : low
                                    ? semanticDanger
                                    : accentPetrol,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  tooltip: 'Opciones',
                  icon: const Icon(Icons.more_horiz_rounded,
                      size: 18, color: textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: surfaceElevated,
                  onSelected: (val) async {
                    if (val == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddProductScreen(vm: vm, itemToEdit: item),
                        ),
                      );
                    } else if (val == 'weigh') {
                      _showWeighAndTareDialog(item);
                    } else if (val == 'copy') {
                      await vm.duplicateItem(item);
                      if (!mounted) return;
                      toast(context, 'Bobina duplicada');
                    } else if (val == 'delete') {
                      _confirmDeleteItem(item);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar ficha', style: TextStyle(fontSize: 12)),
                    ),
                    PopupMenuItem(
                      value: 'weigh',
                      child: Text('Pesar en báscula',
                          style: TextStyle(fontSize: 12)),
                    ),
                    PopupMenuItem(
                      value: 'copy',
                      child: Text('Duplicar', style: TextStyle(fontSize: 12)),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar',
                          style: TextStyle(fontSize: 12, color: semanticDanger)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  Widget _statusBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _adjustTextButton(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: surfaceElevated,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderSubtle),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  void _showWeighAndTareDialog(InventoryItem item) {
    var mode = 0; // 0 = Directo, 1 = Báscula con Tara
    final directCtrl = TextEditingController(
      text: item.stockActual.toStringAsFixed(item.stockActual % 1 == 0 ? 0 : 1),
    );
    final grossCtrl = TextEditingController();
    final tareCtrl = TextEditingController(
      text: item.tareWeight > 0 ? item.tareWeight.toStringAsFixed(0) : '200',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          double? calculatedNet;
          final gross = double.tryParse(grossCtrl.text);
          final tare = double.tryParse(tareCtrl.text) ?? 200.0;
          if (gross != null && gross >= tare) {
            calculatedNet = gross - tare;
          }

          return AlertDialog(
            backgroundColor: surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: borderSubtle),
            ),
            title: Row(
              children: [
                colorSwatchCircle(parseHex(item.colorHex), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ajustar Stock: [${item.brand}] ${item.material}',
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color: ${item.color} · Capacidad inicial: ${item.stockInicial.toInt()} g',
                    style: const TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  // Selector Directo vs Báscula
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => mode = 0),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: mode == 0
                                    ? surfaceCard
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: mode == 0
                                    ? const [
                                        BoxShadow(
                                            color: Color(0x14000000),
                                            blurRadius: 4)
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Entrada directa',
                                style: TextStyle(
                                  color:
                                      mode == 0 ? textPrimary : textSecondary,
                                  fontSize: 12,
                                  fontWeight: mode == 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => mode = 1),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: mode == 1
                                    ? surfaceCard
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: mode == 1
                                    ? const [
                                        BoxShadow(
                                            color: Color(0x14000000),
                                            blurRadius: 4)
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.scale_outlined,
                                      size: 13,
                                      color: mode == 1
                                          ? accentPetrol
                                          : textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Báscula + Tara',
                                    style: TextStyle(
                                      color: mode == 1
                                          ? textPrimary
                                          : textSecondary,
                                      fontSize: 12,
                                      fontWeight: mode == 1
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (mode == 0) ...[
                    TextField(
                      controller: directCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      autofocus: true,
                      style: const TextStyle(color: textPrimary, fontSize: 14),
                      decoration: fieldDecoration(
                        'Gramos netos disponibles',
                        hint: 'Ej: 750.0',
                        suffix: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          child: Text('gramos',
                              style: TextStyle(
                                  color: textSecondary, fontSize: 12)),
                        ),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: grossCtrl,
                      onChanged: (_) => setModalState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      autofocus: true,
                      style: const TextStyle(color: textPrimary, fontSize: 14),
                      decoration: fieldDecoration(
                        'Peso total en báscula',
                        hint: 'Ej: 950 (rollo con plástico)',
                        suffix: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          child: Text('gramos',
                              style: TextStyle(
                                  color: textSecondary, fontSize: 12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: tareCtrl,
                      onChanged: (_) => setModalState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: const TextStyle(color: textPrimary, fontSize: 13),
                      decoration: fieldDecoration(
                        'Tara (peso del carrete plástico vacío)',
                        hint: 'Ej: 200',
                        suffix: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          child: Text('gramos',
                              style: TextStyle(
                                  color: textSecondary, fontSize: 12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentPetrol.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: accentPetrol.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filamento neto restante:',
                            style:
                                TextStyle(color: textSecondary, fontSize: 12),
                          ),
                          Text(
                            calculatedNet != null
                                ? '${calculatedNet.toStringAsFixed(1)} g'
                                : '--',
                            style: const TextStyle(
                              color: accentPetrol,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancelar',
                    style: TextStyle(color: textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  double? finalStock;
                  if (mode == 0) {
                    finalStock = double.tryParse(directCtrl.text);
                  } else {
                    final g = double.tryParse(grossCtrl.text);
                    final t = double.tryParse(tareCtrl.text) ?? 0.0;
                    if (g != null) finalStock = g - t;
                  }

                  if (finalStock == null || finalStock < 0) {
                    toast(context, 'Ingresa una cantidad válida',
                        isError: true);
                    return;
                  }
                  Navigator.pop(dialogCtx);
                  vm.setExactStock(item, finalStock);
                  toast(context,
                      'Stock actualizado a ${finalStock.toStringAsFixed(1)} g');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentPetrol,
                  foregroundColor: textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtle),
        ),
        title: const Text(
          'Eliminar Bobina',
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '¿Deseas eliminar "${item.brand} - ${item.material} (${item.color})" del inventario?',
          style: const TextStyle(color: textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar',
                style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              vm.deleteItem(item);
              toast(context, 'Bobina eliminada del inventario');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: semanticDanger,
              foregroundColor: textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 8. AGREGAR / EDITAR BOBINA O MATERIAL
// ==========================================
class AddProductScreen extends StatefulWidget {
  final InventoryViewModel vm;
  final InventoryItem? itemToEdit;
  const AddProductScreen({super.key, required this.vm, this.itemToEdit});

  @override
  State<AddProductScreen> createState() => _AddProductState();
}

class _AddProductState extends State<AddProductScreen> {
  // Marca
  String brand = 'Genérica';
  bool customBrand = false;
  final brandText = TextEditingController();

  // Material
  String material = 'PLA';
  bool customMaterial = false;
  final materialText = TextEditingController();

  // Acabado / Variante
  String finish = 'Estándar';

  // Color
  String color = '';
  String colorHex = '#FFFFFF';
  bool customColor = false;
  final colorText = TextEditingController();

  // Peso y Tara
  final initialWeightText = TextEditingController(text: '1000');
  final currentWeightText = TextEditingController(text: '1000');
  final tareText = TextEditingController(text: '200');

  // Costo
  final priceText = TextEditingController(text: '0.00');

  // Parámetros técnicos
  double diameter = 1.75;
  final nozzleTempText = TextEditingController();
  final bedTempText = TextEditingController();
  final locationText = TextEditingController();
  final notesText = TextEditingController();

  bool _saving = false;

  static const List<Map<String, String>> _recommendedColors = [
    {'name': 'Blanco', 'hex': '#FFFFFF'},
    {'name': 'Negro', 'hex': '#111111'},
    {'name': 'Gris', 'hex': '#808080'},
    {'name': 'Plata', 'hex': '#C0C0C0'},
    {'name': 'Rojo', 'hex': '#E53935'},
    {'name': 'Naranja', 'hex': '#FB8C00'},
    {'name': 'Amarillo', 'hex': '#FDD835'},
    {'name': 'Verde', 'hex': '#43A047'},
    {'name': 'Verde militar', 'hex': '#556B2F'},
    {'name': 'Azul', 'hex': '#1E88E5'},
    {'name': 'Azul marino', 'hex': '#1A237E'},
    {'name': 'Celeste', 'hex': '#4FC3F7'},
    {'name': 'Petrol', 'hex': '#2E8B98'},
    {'name': 'Morado', 'hex': '#8E24AA'},
    {'name': 'Rosa', 'hex': '#EC407A'},
    {'name': 'Café / Cobre', 'hex': '#6D4C41'},
    {'name': 'Dorado', 'hex': '#D4AF37'},
    {'name': 'Beige / Piel', 'hex': '#D7C4A3'},
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.itemToEdit;
    if (edit != null) {
      brand = edit.brand;
      if (!widget.vm.allBrands.contains(brand)) {
        customBrand = true;
        brandText.text = brand;
      }

      material = edit.material;
      if (!widget.vm.materialCatalog.any((m) => m.nombre == material)) {
        customMaterial = true;
        materialText.text = material;
      }

      finish = edit.finish;
      color = edit.color;
      colorHex = edit.colorHex;
      colorText.text = edit.color;

      initialWeightText.text = edit.stockInicial.toInt().toString();
      currentWeightText.text = edit.stockActual % 1 == 0
          ? edit.stockActual.toInt().toString()
          : edit.stockActual.toStringAsFixed(1);
      tareText.text =
          edit.tareWeight > 0 ? edit.tareWeight.toStringAsFixed(0) : '200';

      priceText.text =
          edit.price > 0 ? edit.price.toStringAsFixed(2) : '0.00';
      diameter = edit.diameter;

      if (edit.tempNozzle != null) {
        nozzleTempText.text = edit.tempNozzle.toString();
      }
      if (edit.tempBed != null) {
        bedTempText.text = edit.tempBed.toString();
      }
      if (edit.location != null) {
        locationText.text = edit.location!;
      }
      if (edit.notes != null) {
        notesText.text = edit.notes!;
      }
    } else {
      if (widget.vm.colorCatalog.isNotEmpty) {
        color = widget.vm.colorCatalog.first.nombre;
        colorHex = widget.vm.colorCatalog.first.hex;
      } else {
        color = 'Negro';
        colorHex = '#111111';
      }
    }
  }

  @override
  void dispose() {
    brandText.dispose();
    materialText.dispose();
    colorText.dispose();
    initialWeightText.dispose();
    currentWeightText.dispose();
    tareText.dispose();
    priceText.dispose();
    nozzleTempText.dispose();
    bedTempText.dispose();
    locationText.dispose();
    notesText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;
    final parsedPrice = double.tryParse(priceText.text) ?? 0.0;
    final parsedGrams = double.tryParse(initialWeightText.text) ?? 1000.0;
    final costPerGram = parsedGrams > 0 ? (parsedPrice / parsedGrams) : 0.0;

    return Scaffold(
      appBar: darkAppBar(
        isEditing ? 'EDITAR BOBINA' : 'AGREGAR BOBINA / MATERIAL',
        () => goBack(context),
      ),
      backgroundColor: bgBase,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. IDENTIFICACIÓN DEL MATERIAL
              formCard(
                title: '1. Identificación del Material',
                subtitle: 'Marca, polímero y acabado de la bobina',
                child: Column(
                  children: [
                    // Selector de Marca
                    DropdownButtonFormField<String>(
                      initialValue: customBrand ? '__custom' : brand,
                      dropdownColor: surfaceElevated,
                      style:
                          const TextStyle(color: textPrimary, fontSize: 13),
                      iconEnabledColor: textSecondary,
                      items: [
                        ...widget.vm.allBrands.map((b) =>
                            DropdownMenuItem(value: b, child: Text(b))),
                        const DropdownMenuItem(
                            value: '__custom',
                            child: Text('+ Otra marca (escribir)')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          customBrand = val == '__custom';
                          if (val != '__custom') {
                            brand = val!;
                          }
                        });
                      },
                      decoration: fieldDecoration('Marca del fabricante',
                          prefix: const Icon(
                              Icons.branding_watermark_outlined,
                              size: 16,
                              color: textSecondary)),
                    ),
                    if (customBrand) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: brandText,
                        style: const TextStyle(
                            color: textPrimary, fontSize: 13),
                        decoration: fieldDecoration(
                          'Nombre de la marca',
                          hint: 'Ej: Polymaker, eSun, Sunlu...',
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Selector de Material / Polímero
                    DropdownButtonFormField<String>(
                      initialValue:
                          customMaterial ? '__custom' : material,
                      dropdownColor: surfaceElevated,
                      style:
                          const TextStyle(color: textPrimary, fontSize: 13),
                      iconEnabledColor: textSecondary,
                      items: [
                        ...widget.vm.materialCatalog.map((m) =>
                            DropdownMenuItem(
                                value: m.nombre, child: Text(m.nombre))),
                        const DropdownMenuItem(
                            value: '__custom',
                            child: Text('+ Otro polímero (escribir)')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          customMaterial = val == '__custom';
                          if (val != '__custom') {
                            material = val!;
                          }
                        });
                      },
                      decoration: fieldDecoration('Tipo de polímero',
                          prefix: const Icon(Icons.category_outlined,
                              size: 16, color: textSecondary)),
                    ),
                    if (customMaterial) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: materialText,
                        style: const TextStyle(
                            color: textPrimary, fontSize: 13),
                        decoration: fieldDecoration(
                          'Nombre del material o compuesto',
                          hint: 'Ej: PETG-CF, ASA, TPU 95A...',
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Acabado / Variante
                    DropdownButtonFormField<String>(
                      initialValue: finish,
                      dropdownColor: surfaceElevated,
                      style:
                          const TextStyle(color: textPrimary, fontSize: 13),
                      iconEnabledColor: textSecondary,
                      items: InventoryViewModel.defaultFinishes
                          .map((f) =>
                              DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => finish = val);
                      },
                      decoration: fieldDecoration('Acabado o variante visual',
                          prefix: const Icon(Icons.auto_awesome_outlined,
                              size: 16, color: textSecondary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. COLOR Y ASPECTO VISUAL
              formCard(
                title: '2. Color del Filamento',
                subtitle:
                    'Selecciona el tono de la paleta y nombra el color',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Malla de colores rápidos
                    const Text(
                      'Tono visual de la bobina:',
                      style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recommendedColors.map((c) {
                        final hex = c['hex']!;
                        final isSelected =
                            colorHex.toUpperCase() == hex.toUpperCase();
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              colorHex = hex;
                              color = c['name']!;
                              colorText.text = c['name']!;
                            });
                          },
                          child: Tooltip(
                            message: c['name']!,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: parseHex(hex),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? accentPetrol
                                      : borderStrong,
                                  width: isSelected ? 2.5 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: accentPetrol
                                              .withValues(alpha: 0.4),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Nombre del color
                    TextField(
                      controller: colorText,
                      onChanged: (x) => color = x,
                      style:
                          const TextStyle(color: textPrimary, fontSize: 13),
                      decoration: fieldDecoration(
                        'Nombre comercial del color',
                        hint: 'Ej: Rojo Carmesí, Gris Galáctico...',
                        prefix: Padding(
                          padding: const EdgeInsets.all(10),
                          child: colorSwatchCircle(parseHex(colorHex),
                              size: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. PESO, CAPACIDAD Y TARA
              formCard(
                title: '3. Capacidad y Pesaje',
                subtitle:
                    'Gramos netos de la bobina y tara para báscula de taller',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botones rápidos para peso inicial
                    const Text(
                      'Capacidad inicial estándar:',
                      style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: ['250', '500', '750', '1000', '2500'].map((g) {
                        return ActionChip(
                          label: Text('$g g'),
                          labelStyle: const TextStyle(
                              color: textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                          backgroundColor: surfaceElevated,
                          side: const BorderSide(color: borderSubtle),
                          onPressed: () {
                            setState(() {
                              initialWeightText.text = g;
                              if (!isEditing) {
                                currentWeightText.text = g;
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: initialWeightText,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                                color: textPrimary, fontSize: 13),
                            decoration: fieldDecoration(
                              'Peso inicial (g)',
                              hint: '1000',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: currentWeightText,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: const TextStyle(
                                color: textPrimary, fontSize: 13),
                            decoration: fieldDecoration(
                              'Peso actual disponible (g)',
                              hint: '1000',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: tareText,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style:
                          const TextStyle(color: textPrimary, fontSize: 13),
                      decoration: fieldDecoration(
                        'Tara del carrete plástico vacío (opcional)',
                        hint: 'Ej: 200 (promedio de carretes plásticos)',
                        suffix: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          child: Text('gramos',
                              style: TextStyle(
                                  color: textSecondary, fontSize: 12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. COSTO Y RENTABILIDAD
              formCard(
                title: '4. Costos y Precios',
                subtitle:
                    'Permite calcular el costo real por gramo en tus impresiones',
                child: Column(
                  children: [
                    TextField(
                      controller: priceText,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (_) => setState(() {}),
                      style:
                          const TextStyle(color: textPrimary, fontSize: 13),
                      decoration: fieldDecoration(
                        'Precio de compra de la bobina',
                        hint: '22.00',
                        prefix: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          child: Text('\$',
                              style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Costo unitario calculado:',
                            style: TextStyle(
                                color: textSecondary, fontSize: 12),
                          ),
                          Text(
                            '\$${costPerGram.toStringAsFixed(4)} / gramo',
                            style: const TextStyle(
                              color: semanticSuccess,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. PARÁMETROS TÉCNICOS Y UBICACIÓN
              formCard(
                title: '5. Parámetros Técnicos y Ubicación',
                subtitle:
                    'Diámetro, temperaturas y posición de almacenamiento',
                child: Column(
                  children: [
                    // Diámetro segmentado
                    Row(
                      children: [
                        const Text(
                          'Diámetro:',
                          style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 14),
                        ChoiceChip(
                          label: const Text('1.75 mm (Estándar)'),
                          selected: diameter == 1.75,
                          onSelected: (sel) {
                            if (sel) setState(() => diameter = 1.75);
                          },
                          selectedColor: accentPetrol,
                          labelStyle: TextStyle(
                            color:
                                diameter == 1.75 ? textPrimary : textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('2.85 mm'),
                          selected: diameter == 2.85,
                          onSelected: (sel) {
                            if (sel) setState(() => diameter = 2.85);
                          },
                          selectedColor: accentPetrol,
                          labelStyle: TextStyle(
                            color:
                                diameter == 2.85 ? textPrimary : textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nozzleTempText,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                                color: textPrimary, fontSize: 13),
                            decoration: fieldDecoration(
                              'Temp. Boquilla (°C)',
                              hint: '210',
                              prefix: const Icon(Icons.thermostat_outlined,
                                  size: 16, color: textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: bedTempText,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                                color: textPrimary, fontSize: 13),
                            decoration: fieldDecoration(
                              'Temp. Cama (°C)',
                              hint: '60',
                              prefix: const Icon(Icons.layers_outlined,
                                  size: 16, color: textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: locationText,
                      style:
                          const TextStyle(color: textPrimary, fontSize: 13),
                      decoration: fieldDecoration(
                        'Ubicación / Almacenamiento',
                        hint: 'Ej: Caja Seca 1, Estante B, Bolsa con desecante...',
                        prefix: const Icon(Icons.place_outlined,
                            size: 16, color: textSecondary),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: notesText,
                      style:
                          const TextStyle(color: textPrimary, fontSize: 13),
                      decoration: fieldDecoration(
                        'Notas adicionales o número de lote',
                        hint: 'Ej: Secado recomendado 6h a 45°C...',
                        prefix: const Icon(Icons.notes_outlined,
                            size: 16, color: textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botón de Guardar
              techButton(
                isEditing ? 'ACTUALIZAR FICHA DE BOBINA' : 'GUARDAR BOBINA EN INVENTARIO',
                _save,
                icon: Icons.save_outlined,
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;

    final finalBrand = customBrand ? brandText.text.trim() : brand.trim();
    final finalMaterial =
        customMaterial ? materialText.text.trim() : material.trim();
    final finalColor = customColor || colorText.text.trim().isNotEmpty
        ? colorText.text.trim()
        : color.trim();

    final initialGrams = double.tryParse(initialWeightText.text) ?? 0;
    final currentGrams = double.tryParse(currentWeightText.text) ?? initialGrams;
    final tare = double.tryParse(tareText.text) ?? 0;
    final price = double.tryParse(priceText.text) ?? 0;
    final nozzle = int.tryParse(nozzleTempText.text);
    final bed = int.tryParse(bedTempText.text);
    final location = locationText.text.trim().isEmpty ? null : locationText.text.trim();
    final notes = notesText.text.trim().isEmpty ? null : notesText.text.trim();

    if (finalBrand.isEmpty) {
      toast(context, 'La marca es obligatoria', isError: true);
      return;
    }
    if (finalMaterial.isEmpty) {
      toast(context, 'El nombre del material es obligatorio', isError: true);
      return;
    }
    if (finalColor.isEmpty) {
      toast(context, 'El color es obligatorio', isError: true);
      return;
    }
    if (initialGrams <= 0) {
      toast(context, 'Ingresa un peso inicial válido en gramos', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.itemToEdit != null) {
        final updated = widget.itemToEdit!.copyWith(
          brand: finalBrand,
          material: finalMaterial,
          finish: finish,
          color: finalColor,
          colorHex: colorHex,
          stockInicial: initialGrams,
          stockActual: currentGrams,
          tareWeight: tare,
          price: price,
          diameter: diameter,
          tempNozzle: nozzle,
          tempBed: bed,
          location: location,
          notes: notes,
        );
        await widget.vm.updateItem(updated);
        if (!mounted) return;
        toast(context, 'Ficha de bobina actualizada');
      } else {
        final newItem = InventoryItem(
          brand: finalBrand,
          material: finalMaterial,
          finish: finish,
          color: finalColor,
          colorHex: colorHex,
          stockInicial: initialGrams,
          stockActual: currentGrams,
          tareWeight: tare,
          price: price,
          diameter: diameter,
          tempNozzle: nozzle,
          tempBed: bed,
          location: location,
          notes: notes,
        );
        await widget.vm.addItem(newItem);
        if (!mounted) return;
        toast(context, 'Bobina agregada al inventario');
      }
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
