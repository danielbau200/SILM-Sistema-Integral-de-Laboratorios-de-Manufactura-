import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

// ============================================================================
// CONSTANTES DE COLOR Y ESTILO DEL REDISEÑO "LISTA TIPO AJUSTES"
// ============================================================================

class AnalyticsPalette {
  static bool get isDark => isVoxelDarkMode;

  static Color get background =>
      isDark ? bgBase : const Color(0xFFF7F8FA);
  static Color get cardBg =>
      isDark ? surfaceCard : const Color(0xFFFFFFFF);
  static Color get border =>
      isDark ? borderSubtle : const Color(0xFFE6E8EE);
  static Color get textPrimary =>
      isDark ? const Color(0xFFF4F4F5) : const Color(0xFF111827);
  static Color get textSecondary =>
      isDark ? const Color(0xFFA1A1AA) : const Color(0xFF5B6472);
  static Color get accent =>
      isDark ? const Color(0xFF4F75FF) : const Color(0xFF2F5BEA);
  static Color get accentLight =>
      isDark ? const Color(0xFF1E2540) : const Color(0xFFEEF2FF);
  static Color get accentDark =>
      isDark ? const Color(0xFF8DA4FF) : const Color(0xFF2347C5);

  // Estados
  static Color get greenText =>
      isDark ? const Color(0xFF4ADE80) : const Color(0xFF17663A);
  static Color get greenBg =>
      isDark ? const Color(0xFF132D21) : const Color(0xFFE7F5EC);
  static Color get amberText =>
      isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
  static Color get amberBg =>
      isDark ? const Color(0xFF332410) : const Color(0xFFFEF3C7);
  static Color get redText =>
      isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
  static Color get redBg =>
      isDark ? const Color(0xFF361818) : const Color(0xFFFEE2E2);

  // Pista de barras e iconos neutros
  static Color get track =>
      isDark ? const Color(0xFF22242B) : const Color(0xFFECEFF4);

  // Fondo para segmentos activos
  static Color get segmentActiveBg =>
      isDark ? const Color(0xFF262933) : const Color(0xFFFFFFFF);

  // Sombra sutil requerida
  static List<BoxShadow> get cardShadow => isDark
      ? const []
      : const [
          BoxShadow(
            color: Color.fromRGBO(16, 24, 40, 0.04),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ];
}

// ============================================================================
// ENUM DE SECCIONES DE NAVEGACIÓN
// ============================================================================

enum AnalyticsSection {
  resumen,
  evolucion,
  composicion,
  proyectos,
  impresoras,
  almacen,
  comunidad,
}

// ============================================================================
// WIDGET 1: HEADER SUPERIOR (AnalisisHeader)
// ============================================================================

class AnalisisHeader extends StatelessWidget {
  final String periodLabel;
  final int totalOrders;
  final Widget cicloSelector;
  final bool compareWithPrevious;
  final ValueChanged<bool> onCompareChanged;
  final VoidCallback onSearch;
  final VoidCallback onExport;
  final bool isCompact;
  final Widget? leading;

  const AnalisisHeader({
    super.key,
    required this.periodLabel,
    required this.totalOrders,
    required this.cicloSelector,
    required this.compareWithPrevious,
    required this.onCompareChanged,
    required this.onSearch,
    required this.onExport,
    this.isCompact = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return WindowDragArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AnalyticsPalette.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Análisis de Producción',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AnalyticsPalette.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Laboratorio · $periodLabel · $totalOrders órdenes',
                          style: TextStyle(
                            fontSize: 12,
                            color: AnalyticsPalette.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search_rounded,
                        color: AnalyticsPalette.textSecondary),
                    tooltip: 'Buscar ⌘F',
                    onPressed: onSearch,
                  ),
                  IconButton(
                    icon: Icon(Icons.ios_share_rounded,
                        color: AnalyticsPalette.textSecondary),
                    tooltip: 'Exportar informe',
                    onPressed: onExport,
                  ),
                  if (SilmWindowControls.isCustomFrameSupported) ...[
                    const SizedBox(width: 6),
                    WindowCaptionButtons(
                      iconColor: AnalyticsPalette.textSecondary,
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: cicloSelector),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Comparar',
                      style: TextStyle(
                        fontSize: 12,
                        color: AnalyticsPalette.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Switch(
                      value: compareWithPrevious,
                      activeThumbColor: AnalyticsPalette.accent,
                      onChanged: onCompareChanged,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ),
      );
    }

    return WindowDragArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 10, 12, 14),
        color: AnalyticsPalette.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: leading!,
            ),
            const SizedBox(width: 12),
          ],
          // Título e info de periodo
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Análisis de Producción',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AnalyticsPalette.textPrimary,
                  fontFamily: 'Inter',
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Laboratorio de Manufactura · $periodLabel · $totalOrders órdenes',
                style: TextStyle(
                  fontSize: 13,
                  color: AnalyticsPalette.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
            ),
          ),

          const Spacer(),

          // Controles de la derecha
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Selector segmentado de ciclo
              cicloSelector,

              const SizedBox(width: 16),

              // 2. Interruptor "Comparar ciclo"
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Comparar ciclo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AnalyticsPalette.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Transform.scale(
                    scale: 0.82,
                    child: Switch(
                      value: compareWithPrevious,
                      activeThumbColor: AnalyticsPalette.accent,
                      activeTrackColor: AnalyticsPalette.accent.withValues(alpha: 0.35),
                      inactiveThumbColor: AnalyticsPalette.isDark ? const Color(0xFFA1A1AA) : Colors.white,
                      inactiveTrackColor: AnalyticsPalette.track,
                      onChanged: onCompareChanged,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // 3. Botón "Buscar ⌘F"
              OutlinedButton.icon(
                onPressed: onSearch,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: BorderSide(color: AnalyticsPalette.border, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  foregroundColor: AnalyticsPalette.textPrimary,
                ),
                icon: Icon(Icons.search_rounded,
                    size: 15, color: AnalyticsPalette.textSecondary),
                label: const Text(
                  'Buscar ⌘F',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 4. Botón "Exportar"
              OutlinedButton(
                onPressed: onExport,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  side: BorderSide(color: AnalyticsPalette.border, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  foregroundColor: AnalyticsPalette.textPrimary,
                ),
                child: const Text(
                  'Exportar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          ),
          if (SilmWindowControls.isCustomFrameSupported) ...[
            const SizedBox(width: 12),
            WindowCaptionButtons(
              iconColor: AnalyticsPalette.textSecondary,
            ),
          ],
        ],
      ),
      ),
    );
  }
}

// ============================================================================
// WIDGET 2: SELECTOR DE CICLO (CicloSelector)
// ============================================================================

class CicloSelector extends StatelessWidget {
  final String activeSemesterLabel;
  final bool isCurrent;
  final bool isPrevious;
  final bool isHistory;
  final VoidCallback onSelectCurrent;
  final VoidCallback onSelectPrevious;
  final ValueChanged<String> onSelectHistory;
  final List<({String key, String label})> historyOptions;

  const CicloSelector({
    super.key,
    required this.activeSemesterLabel,
    required this.isCurrent,
    required this.isPrevious,
    required this.isHistory,
    required this.onSelectCurrent,
    required this.onSelectPrevious,
    required this.onSelectHistory,
    required this.historyOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AnalyticsPalette.track,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AnalyticsPalette.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Sem. actual
          _buildItem(
            label: 'Sem. actual',
            isSelected: isCurrent,
            onTap: onSelectCurrent,
          ),

          // 2. Sem. anterior
          _buildItem(
            label: 'Sem. anterior',
            isSelected: isPrevious,
            onTap: onSelectPrevious,
          ),

          // 3. Historial ▾
          PopupMenuButton<String>(
            tooltip: 'Historial de semestres',
            color: AnalyticsPalette.cardBg,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AnalyticsPalette.border, width: 0.8),
            ),
            offset: const Offset(0, 36),
            onSelected: onSelectHistory,
            itemBuilder: (context) {
              return [
                PopupMenuItem<String>(
                  value: 'TODOS',
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded,
                          size: 16, color: AnalyticsPalette.accent),
                      const SizedBox(width: 8),
                      Text(
                        'Ver todo el histórico',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AnalyticsPalette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                ...historyOptions.map(
                  (opt) => PopupMenuItem<String>(
                    value: opt.key,
                    child: Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AnalyticsPalette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ];
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isHistory ? AnalyticsPalette.segmentActiveBg : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: isHistory ? AnalyticsPalette.cardShadow : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Historial',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isHistory ? FontWeight.w600 : FontWeight.w500,
                      color: isHistory
                          ? AnalyticsPalette.textPrimary
                          : AnalyticsPalette.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 16,
                    color: isHistory
                        ? AnalyticsPalette.textPrimary
                        : AnalyticsPalette.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AnalyticsPalette.segmentActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected ? AnalyticsPalette.cardShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? AnalyticsPalette.textPrimary
                : AnalyticsPalette.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET 3: ITEM DE NAVEGACIÓN IZQUIERDO (NavSeccionItem)
// ============================================================================

class NavSeccionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String previewText;
  final bool isSelected;
  final VoidCallback onTap;

  const NavSeccionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.previewText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AnalyticsPalette.accentLight : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Cuadro del icono (32x32 px, radio 9)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AnalyticsPalette.accent
                      : AnalyticsPalette.track,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? Colors.white
                      : AnalyticsPalette.textSecondary,
                ),
              ),

              const SizedBox(width: 12),

              // Etiqueta de la sección
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: AnalyticsPalette.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),

              const Spacer(),

              // Vista previa dinámica
              Text(
                previewText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AnalyticsPalette.accentDark
                      : AnalyticsPalette.textSecondary,
                  fontFamily: 'Inter',
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),

              const SizedBox(width: 6),

              // Chevron ›
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isSelected
                    ? AnalyticsPalette.accent
                    : AnalyticsPalette.textSecondary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET 4: LISTA DE NAVEGACIÓN COMPLETA (NavSeccionesLista)
// ============================================================================

class NavSeccionesLista extends StatelessWidget {
  final AnalyticsSection selectedSection;
  final ValueChanged<AnalyticsSection> onSelectSection;
  final String previewResumen;
  final String previewEvolucion;
  final String previewComposicion;
  final String previewProyectos;
  final String previewImpresoras;
  final String previewAlmacen;
  final String previewComunidad;

  const NavSeccionesLista({
    super.key,
    required this.selectedSection,
    required this.onSelectSection,
    required this.previewResumen,
    required this.previewEvolucion,
    required this.previewComposicion,
    required this.previewProyectos,
    required this.previewImpresoras,
    required this.previewAlmacen,
    required this.previewComunidad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AnalyticsPalette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AnalyticsPalette.border, width: 1),
        boxShadow: AnalyticsPalette.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resumen (sin encabezado superior)
          NavSeccionItem(
            icon: Icons.grid_view_rounded,
            label: 'Resumen',
            previewText: previewResumen,
            isSelected: selectedSection == AnalyticsSection.resumen,
            onTap: () => onSelectSection(AnalyticsSection.resumen),
          ),

          const SizedBox(height: 14),
          _buildGroupHeader('PRODUCCIÓN'),
          const SizedBox(height: 4),

          NavSeccionItem(
            icon: Icons.trending_up_rounded,
            label: 'Evolución',
            previewText: previewEvolucion,
            isSelected: selectedSection == AnalyticsSection.evolucion,
            onTap: () => onSelectSection(AnalyticsSection.evolucion),
          ),
          NavSeccionItem(
            icon: Icons.pie_chart_outline_rounded,
            label: 'Composición',
            previewText: previewComposicion,
            isSelected: selectedSection == AnalyticsSection.composicion,
            onTap: () => onSelectSection(AnalyticsSection.composicion),
          ),
          NavSeccionItem(
            icon: Icons.format_list_bulleted_rounded,
            label: 'Proyectos',
            previewText: previewProyectos,
            isSelected: selectedSection == AnalyticsSection.proyectos,
            onTap: () => onSelectSection(AnalyticsSection.proyectos),
          ),

          const SizedBox(height: 14),
          _buildGroupHeader('RECURSOS'),
          const SizedBox(height: 4),

          NavSeccionItem(
            icon: Icons.print_outlined,
            label: 'Impresoras',
            previewText: previewImpresoras,
            isSelected: selectedSection == AnalyticsSection.impresoras,
            onTap: () => onSelectSection(AnalyticsSection.impresoras),
          ),
          NavSeccionItem(
            icon: Icons.inventory_2_outlined,
            label: 'Almacén',
            previewText: previewAlmacen,
            isSelected: selectedSection == AnalyticsSection.almacen,
            onTap: () => onSelectSection(AnalyticsSection.almacen),
          ),

          const SizedBox(height: 14),
          _buildGroupHeader('PERSONAS'),
          const SizedBox(height: 4),

          NavSeccionItem(
            icon: Icons.group_outlined,
            label: 'Comunidad',
            previewText: previewComunidad,
            isSelected: selectedSection == AnalyticsSection.comunidad,
            onTap: () => onSelectSection(AnalyticsSection.comunidad),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AnalyticsPalette.textSecondary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET 5: BLOQUE DE KPI REUTILIZABLE (KpiBloque)
// ============================================================================

class KpiBloque extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String sublabel;
  final String? comparisonBadge;
  final bool isPositiveComparison;

  const KpiBloque({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.sublabel,
    this.comparisonBadge,
    this.isPositiveComparison = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AnalyticsPalette.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w600,
                color: AnalyticsPalette.textPrimary,
                fontFamily: 'Inter',
                letterSpacing: -1.0,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AnalyticsPalette.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 12,
                color: AnalyticsPalette.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            if (comparisonBadge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isPositiveComparison
                      ? AnalyticsPalette.greenBg
                      : AnalyticsPalette.redBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  comparisonBadge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPositiveComparison
                        ? AnalyticsPalette.greenText
                        : AnalyticsPalette.redText,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// WIDGET 6: BARRA DE PROGRESO REUTILIZABLE (BarraProgreso)
// ============================================================================

class BarraProgreso extends StatelessWidget {
  final double percentage; // 0.0 a 1.0
  final Color? fillColor;
  final double height;

  const BarraProgreso({
    super.key,
    required this.percentage,
    this.fillColor,
    this.height = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0.0, 1.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AnalyticsPalette.track,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            color: fillColor ?? AnalyticsPalette.accent,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET 7: INSIGNIA DE ESTADO / PILL (InsigniaEstado)
// ============================================================================

class InsigniaEstado extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color bgColor;

  const InsigniaEstado({
    super.key,
    required this.text,
    required this.textColor,
    required this.bgColor,
  });

  factory InsigniaEstado.positivo(String text) => InsigniaEstado(
        text: text,
        textColor: AnalyticsPalette.greenText,
        bgColor: AnalyticsPalette.greenBg,
      );

  factory InsigniaEstado.alerta(String text) => InsigniaEstado(
        text: text,
        textColor: AnalyticsPalette.amberText,
        bgColor: AnalyticsPalette.amberBg,
      );

  factory InsigniaEstado.critico(String text) => InsigniaEstado(
        text: text,
        textColor: AnalyticsPalette.redText,
        bgColor: AnalyticsPalette.redBg,
      );

  factory InsigniaEstado.info(String text) => InsigniaEstado(
        text: text,
        textColor: AnalyticsPalette.accentDark,
        bgColor: AnalyticsPalette.accentLight,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET 8: DETALLE RESUMEN (DetalleResumen)
// ============================================================================

class DetalleResumen extends StatelessWidget {
  final String periodDescription;
  final double totalInversion;
  final double totalKg;
  final int totalTandas;
  final int totalPiezas;
  final double avgPiezasPorTanda;
  final String peakMonth;
  final double peakKg;
  final int metricIndex; // 0 = Material, 1 = Piezas
  final ValueChanged<int> onMetricChanged;
  final Widget chartWidget;
  final Widget? filterBanner;
  final String? comparisonInversionDelta;
  final bool isComparisonInversionPositive;

  const DetalleResumen({
    super.key,
    required this.periodDescription,
    required this.totalInversion,
    required this.totalKg,
    required this.totalTandas,
    required this.totalPiezas,
    required this.avgPiezasPorTanda,
    required this.peakMonth,
    required this.peakKg,
    required this.metricIndex,
    required this.onMetricChanged,
    required this.chartWidget,
    this.filterBanner,
    this.comparisonInversionDelta,
    this.isComparisonInversionPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Text(
          'Resumen del ciclo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AnalyticsPalette.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 3),
        Text(
          periodDescription,
          style: TextStyle(
            fontSize: 12,
            color: AnalyticsPalette.textSecondary,
            fontFamily: 'Inter',
          ),
        ),

        if (filterBanner != null) ...[
          const SizedBox(height: 12),
          filterBanner!,
        ],

        const SizedBox(height: 24),

        // Fila de 3 KPIs separados por líneas verticales finas
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: KpiBloque(
                label: 'Inversión en insumos',
                value: '\$${totalInversion.toStringAsFixed(2)}',
                unit: 'MXN',
                sublabel: 'Total acumulado',
                comparisonBadge: comparisonInversionDelta,
                isPositiveComparison: isComparisonInversionPositive,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: KpiBloque(
                label: 'Material usado',
                value: totalKg.toStringAsFixed(2),
                unit: 'kg',
                sublabel: 'en $totalTandas tandas',
              ),
            ),
            _buildDivider(),
            Expanded(
              child: KpiBloque(
                label: 'Piezas fabricadas',
                value: '$totalPiezas',
                unit: 'uds',
                sublabel: '~${avgPiezasPorTanda.toStringAsFixed(1)} por tanda',
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),
        Divider(color: AnalyticsPalette.border, height: 1),
        const SizedBox(height: 22),

        // Subtítulo Evolución mensual + píldora pico + selector Material/Piezas
        Row(
          children: [
            Text(
              'Evolución mensual',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AnalyticsPalette.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const Spacer(),
            if (peakMonth.isNotEmpty && peakKg > 0) ...[
              InsigniaEstado.info('Mes pico · $peakMonth · ${peakKg.toStringAsFixed(2)} kg'),
              const SizedBox(width: 10),
            ],
            // Selector Material / Piezas
            _buildMetricToggle(),
          ],
        ),

        const SizedBox(height: 16),

        // Gráfica de curva suave
        chartWidget,

        const SizedBox(height: 12),

        // Nota instructiva
        Text(
          'Haz clic en un mes para filtrar todo el panel. Vuelve a hacer clic para ver el ciclo completo.',
          style: TextStyle(
            fontSize: 12,
            color: AnalyticsPalette.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AnalyticsPalette.border,
    );
  }

  Widget _buildMetricToggle() {
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AnalyticsPalette.track,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AnalyticsPalette.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(0, 'Material'),
          _buildToggleOption(1, 'Piezas'),
        ],
      ),
    );
  }

  Widget _buildToggleOption(int index, String label) {
    final isSelected = metricIndex == index;
    return InkWell(
      onTap: () => onMetricChanged(index),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AnalyticsPalette.segmentActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          boxShadow: isSelected ? AnalyticsPalette.cardShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? AnalyticsPalette.textPrimary
                : AnalyticsPalette.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET 9: DETALLE PROYECTOS DE MAYOR DEMANDA (DetalleProyectos)
// ============================================================================

class DetalleProyectos extends StatelessWidget {
  final List<({
    String name,
    int pieces,
    int tandas,
    double grams,
    double percentage,
  })> projects;
  final ValueChanged<String> onSelectProject;

  const DetalleProyectos({
    super.key,
    required this.projects,
    required this.onSelectProject,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Text(
          'Proyectos de mayor demanda',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AnalyticsPalette.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Ordenados por material consumido',
          style: TextStyle(
            fontSize: 12,
            color: AnalyticsPalette.textSecondary,
            fontFamily: 'Inter',
          ),
        ),

        const SizedBox(height: 20),

        if (projects.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No hay proyectos registrados en este periodo',
                style: TextStyle(
                  fontSize: 13,
                  color: AnalyticsPalette.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: projects.length,
            separatorBuilder: (_, __) =>
                Divider(color: AnalyticsPalette.border, height: 1),
            itemBuilder: (context, index) {
              final proj = projects[index];
              final numStr = (index + 1).toString().padLeft(2, '0');
              final weightStr = proj.grams >= 1000
                  ? '${(proj.grams / 1000).toStringAsFixed(2)} kg'
                  : '${proj.grams.toStringAsFixed(0)} g';
              final pctStr = '${(proj.percentage * 100).toStringAsFixed(0)}%';

              return InkWell(
                onTap: () => onSelectProject(proj.name),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    children: [
                      // Número (01, 02...)
                      SizedBox(
                        width: 30,
                        child: Text(
                          numStr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AnalyticsPalette.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),

                      // Nombre y tandas
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              proj.name,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AnalyticsPalette.textPrimary,
                                fontFamily: 'Inter',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${proj.pieces} piezas · ${proj.tandas} tandas',
                              style: TextStyle(
                                fontSize: 12,
                                color: AnalyticsPalette.textSecondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Barra fina de porcentaje
                      Expanded(
                        flex: 4,
                        child: BarraProgreso(
                          percentage: proj.percentage,
                          fillColor: AnalyticsPalette.accent,
                          height: 6,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Peso
                      SizedBox(
                        width: 70,
                        child: Text(
                          weightStr,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AnalyticsPalette.textPrimary,
                            fontFamily: 'Inter',
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Porcentaje
                      SizedBox(
                        width: 40,
                        child: Text(
                          pctStr,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            color: AnalyticsPalette.textSecondary,
                            fontFamily: 'Inter',
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Chevron
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AnalyticsPalette.textSecondary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 22),

        // Nota instructiva
        Text(
          'Selecciona una pieza para ver en qué impresora se fabricó, su costo por unidad, fechas y especificaciones.',
          style: TextStyle(
            fontSize: 12,
            color: AnalyticsPalette.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// WIDGET 10: DETALLE PARQUE DE IMPRESORAS (DetalleImpresoras)
// ============================================================================

class DetalleImpresoras extends StatelessWidget {
  final int activePrintersCount;
  final List<({
    String name,
    double grams,
    int tandas,
    int pieces,
    double percentage,
  })> printers;
  final bool showAll;
  final VoidCallback onToggleShowAll;

  const DetalleImpresoras({
    super.key,
    required this.activePrintersCount,
    required this.printers,
    required this.showAll,
    required this.onToggleShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final displayed = showAll ? printers : printers.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parque de impresoras',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AnalyticsPalette.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Distribución de carga por equipo',
                  style: TextStyle(
                    fontSize: 12,
                    color: AnalyticsPalette.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const Spacer(),
            InsigniaEstado.info('$activePrintersCount activas'),
          ],
        ),

        const SizedBox(height: 22),

        if (printers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No hay actividad registrada en impresoras para este periodo',
                style: TextStyle(
                  fontSize: 13,
                  color: AnalyticsPalette.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayed.length,
            separatorBuilder: (_, __) =>
                Divider(color: AnalyticsPalette.border, height: 1),
            itemBuilder: (context, index) {
              final p = displayed[index];
              final isTop = index == 0;
              final weightStr = p.grams >= 1000
                  ? '${(p.grams / 1000).toStringAsFixed(2)} kg'
                  : '${p.grams.toStringAsFixed(0)} g';
              final pctStr = '${(p.percentage * 100).toStringAsFixed(0)}% del laboratorio';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila 1: Nombre (+ etiqueta verde Mayor carga) y peso
                    Row(
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AnalyticsPalette.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        if (isTop) ...[
                          const SizedBox(width: 8),
                          InsigniaEstado.positivo('Mayor carga'),
                        ],
                        const Spacer(),
                        Text(
                          weightStr,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AnalyticsPalette.textPrimary,
                            fontFamily: 'Inter',
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Fila 2: Barra fina de progreso
                    BarraProgreso(
                      percentage: p.percentage,
                      fillColor: AnalyticsPalette.accent,
                      height: 6,
                    ),

                    const SizedBox(height: 6),

                    // Fila 3: Tandas/piezas a la izquierda, % del laboratorio a la derecha
                    Row(
                      children: [
                        Text(
                          '${p.tandas} tandas · ${p.pieces} piezas',
                          style: TextStyle(
                            fontSize: 12,
                            color: AnalyticsPalette.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          pctStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: AnalyticsPalette.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

        if (printers.length > 4) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: onToggleShowAll,
              child: Text(
                showAll
                    ? 'Ver menos ▴'
                    : 'Ver las ${printers.length} Impresoras (${printers.length - 4} más) ▾',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AnalyticsPalette.accent,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// WIDGET 11: DETALLE ALMACÉN Y BOBINAS (DetalleAlmacen)
// ============================================================================

class DetalleAlmacen extends StatelessWidget {
  final String statusText;
  final int statusVariant; // 0 = óptimo, 1 = advertencia, 2 = crítico
  final double estimatedAutonomyWeeks;
  final double availableKg;
  final int activeSpoolsCount;
  final List<({
    String name,
    Color color,
    double remainingGrams,
    double percentage,
  })> spools;
  final bool showAll;
  final VoidCallback onToggleShowAll;

  const DetalleAlmacen({
    super.key,
    required this.statusText,
    required this.statusVariant,
    required this.estimatedAutonomyWeeks,
    required this.availableKg,
    required this.activeSpoolsCount,
    required this.spools,
    required this.showAll,
    required this.onToggleShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final displayed = showAll ? spools : spools.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Almacén y bobinas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AnalyticsPalette.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Estado del inventario de filamento',
                  style: TextStyle(
                    fontSize: 12,
                    color: AnalyticsPalette.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (statusVariant == 0)
              InsigniaEstado.positivo(statusText)
            else if (statusVariant == 1)
              InsigniaEstado.alerta(statusText)
            else
              InsigniaEstado.critico(statusText),
          ],
        ),

        const SizedBox(height: 24),

        // 3 KPIs
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: KpiBloque(
                label: 'Autonomía estimada',
                value: '~${estimatedAutonomyWeeks.toInt()}',
                unit: 'semanas',
                sublabel: 'al ritmo actual de consumo',
              ),
            ),
            _buildDivider(),
            Expanded(
              child: KpiBloque(
                label: 'Reserva disponible',
                value: availableKg.toStringAsFixed(2),
                unit: 'kg',
                sublabel: 'lista para usarse',
              ),
            ),
            _buildDivider(),
            Expanded(
              child: KpiBloque(
                label: 'Carretes activos',
                value: '$activeSpoolsCount',
                unit: 'bobinas',
                sublabel: 'en inventario',
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),
        Divider(color: AnalyticsPalette.border, height: 1),
        const SizedBox(height: 20),

        // Título de lista
        Text(
          'Filamentos en uso',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AnalyticsPalette.textPrimary,
            fontFamily: 'Inter',
          ),
        ),

        const SizedBox(height: 14),

        if (spools.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No hay bobinas activas registradas',
              style: TextStyle(
                fontSize: 13,
                color: AnalyticsPalette.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayed.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final sp = displayed[index];
              final pctStr = '${(sp.percentage * 100).toStringAsFixed(0)}%';

              return Row(
                children: [
                  // Punto con el color real
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: sp.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Nombre
                  SizedBox(
                    width: 150,
                    child: Text(
                      sp.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AnalyticsPalette.textPrimary,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Barra verde fina
                  Expanded(
                    child: BarraProgreso(
                      percentage: sp.percentage,
                      fillColor: const Color(0xFF10B981),
                      height: 6,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Gramos restantes
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${sp.remainingGrams.toStringAsFixed(0)} g',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: AnalyticsPalette.textPrimary,
                        fontFamily: 'Inter',
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Porcentaje
                  SizedBox(
                    width: 44,
                    child: Text(
                      pctStr,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: AnalyticsPalette.textSecondary,
                        fontFamily: 'Inter',
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        if (spools.length > 4) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: onToggleShowAll,
              child: Text(
                showAll
                    ? 'Ver menos ▴'
                    : 'Ver las ${spools.length} bobinas (${spools.length - 4} más) ▾',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AnalyticsPalette.accent,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AnalyticsPalette.border,
    );
  }
}

// ============================================================================
// WIDGET 12: DETALLE COMUNIDAD (DetalleComunidad)
// ============================================================================

class DetalleComunidad extends StatelessWidget {
  final int totalUsers;
  final int studentsCount;
  final int facultyCount;
  final int othersCount;

  const DetalleComunidad({
    super.key,
    required this.totalUsers,
    required this.studentsCount,
    required this.facultyCount,
    required this.othersCount,
  });

  @override
  Widget build(BuildContext context) {
    final sPct = totalUsers > 0 ? studentsCount / totalUsers : 0.0;
    final fPct = totalUsers > 0 ? facultyCount / totalUsers : 0.0;
    final oPct = totalUsers > 0 ? othersCount / totalUsers : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comunidad atendida',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AnalyticsPalette.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Estudiantes, docentes y departamentos beneficiados',
                  style: TextStyle(
                    fontSize: 12,
                    color: AnalyticsPalette.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const Spacer(),
            InsigniaEstado.info('$totalUsers usuarios'),
          ],
        ),

        const SizedBox(height: 24),

        // KPI Principal
        KpiBloque(
          label: 'Usuarios activos en el ciclo',
          value: '$totalUsers',
          unit: 'personas',
          sublabel: 'que han solicitado o impreso proyectos',
        ),

        const SizedBox(height: 24),

        // Barra dividida
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                if (sPct > 0)
                  Expanded(
                    flex: (sPct * 100).toInt(),
                    child: Container(color: AnalyticsPalette.accent),
                  ),
                if (fPct > 0)
                  Expanded(
                    flex: (fPct * 100).toInt(),
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                if (oPct > 0)
                  Expanded(
                    flex: (oPct * 100).toInt(),
                    child: Container(color: const Color(0xFFF59E0B)),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Desglose
        _buildUserTypeRow(
          icon: Icons.school_outlined,
          color: AnalyticsPalette.accent,
          title: 'Alumnos / Estudiantes',
          count: studentsCount,
          percentage: sPct,
        ),
        Divider(color: AnalyticsPalette.border, height: 16),
        _buildUserTypeRow(
          icon: Icons.psychology_outlined,
          color: const Color(0xFF10B981),
          title: 'Docentes / Investigadores',
          count: facultyCount,
          percentage: fPct,
        ),
        if (othersCount > 0) ...[
          Divider(color: AnalyticsPalette.border, height: 16),
          _buildUserTypeRow(
            icon: Icons.person_outline_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Otros solicitantes / Externos',
            count: othersCount,
            percentage: oPct,
          ),
        ],
      ],
    );
  }

  Widget _buildUserTypeRow({
    required IconData icon,
    required Color color,
    required String title,
    required int count,
    required double percentage,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AnalyticsPalette.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const Spacer(),
        Text(
          '$count usuarios',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AnalyticsPalette.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '(${(percentage * 100).toStringAsFixed(0)}%)',
          style: TextStyle(
            fontSize: 12.5,
            color: AnalyticsPalette.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}


// ============================================================================
// WIDGET 13: DETALLE EVOLUCIÓN (DetalleEvolucion)
// ============================================================================

class DetalleEvolucion extends StatelessWidget {
  final String peakMonth;
  final double peakVal;
  final int metricIndex;
  final ValueChanged<int> onMetricChanged;
  final Widget chartWidget;
  final Widget? filterBanner;

  const DetalleEvolucion({
    super.key,
    required this.peakMonth,
    required this.peakVal,
    required this.metricIndex,
    required this.onMetricChanged,
    required this.chartWidget,
    this.filterBanner,
  });

  @override
  Widget build(BuildContext context) {
    final peakValStr = metricIndex == 0
        ? (peakVal >= 1000
            ? '${(peakVal / 1000).toStringAsFixed(2)} kg'
            : '${peakVal.toStringAsFixed(0)} g')
        : '${peakVal.toInt()} uds';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evolución de la producción',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AnalyticsPalette.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tendencia temporal de material y piezas fabricadas',
                  style: TextStyle(
                    fontSize: 12,
                    color: AnalyticsPalette.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (peakMonth.isNotEmpty && peakVal > 0)
              InsigniaEstado.info('Pico en $peakMonth ($peakValStr)'),
            const SizedBox(width: 10),
            _buildMetricToggle(),
          ],
        ),

        if (filterBanner != null) ...[
          const SizedBox(height: 12),
          filterBanner!,
        ],

        const SizedBox(height: 24),

        // Gráfica de mayor tamaño
        chartWidget,

        const SizedBox(height: 16),

        Text(
          'Haz clic en un mes para filtrar todo el panel. Vuelve a hacer clic para ver el ciclo completo.',
          style: TextStyle(
            fontSize: 12,
            color: AnalyticsPalette.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricToggle() {
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AnalyticsPalette.track,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AnalyticsPalette.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(0, 'Material'),
          _buildToggleOption(1, 'Piezas'),
        ],
      ),
    );
  }

  Widget _buildToggleOption(int index, String label) {
    final isSelected = metricIndex == index;
    return InkWell(
      onTap: () => onMetricChanged(index),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AnalyticsPalette.segmentActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          boxShadow: isSelected ? AnalyticsPalette.cardShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? AnalyticsPalette.textPrimary
                : AnalyticsPalette.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET 14: DETALLE COMPOSICIÓN (DetalleComposicion)
// ============================================================================

class DetalleComposicion extends StatelessWidget {
  final int tabIndex; // 0 = Material, 1 = Categoría, 2 = Color
  final ValueChanged<int> onTabChanged;
  final List<({String label, double grams, Color color, double percentage})> slices;
  final double totalGrams;
  final String dominantLabel;
  final double dominantPercentage;

  const DetalleComposicion({
    super.key,
    required this.tabIndex,
    required this.onTabChanged,
    required this.slices,
    required this.totalGrams,
    required this.dominantLabel,
    required this.dominantPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final pctStr = '${(dominantPercentage * 100).toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Composición',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AnalyticsPalette.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Distribución de material, categorías y colores',
                  style: TextStyle(
                    fontSize: 12,
                    color: AnalyticsPalette.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Pestañas Material / Categoría / Color
            _buildTabSelector(),
          ],
        ),

        const SizedBox(height: 28),

        if (slices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                'No hay datos de composición para este periodo',
                style: TextStyle(
                  fontSize: 13,
                  color: AnalyticsPalette.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Dona con porcentaje dominante al centro
              SizedBox(
                width: 170,
                height: 170,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(160, 160),
                      painter: _SimpleDonutPainter(
                        slices: slices,
                        totalGrams: totalGrams,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pctStr,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AnalyticsPalette.textPrimary,
                            fontFamily: 'Inter',
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          dominantLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AnalyticsPalette.textSecondary,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 32),

              // Lista de desglose
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: slices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final sl = slices[index];
                    final gStr = sl.grams >= 1000
                        ? '${(sl.grams / 1000).toStringAsFixed(2)} kg'
                        : '${sl.grams.toStringAsFixed(0)} g';
                    final slPctStr = '${(sl.percentage * 100).toStringAsFixed(0)}%';

                    return Row(
                      children: [
                        // Punto de color
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: sl.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Nombre
                        Expanded(
                          flex: 3,
                          child: Text(
                            sl.label,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AnalyticsPalette.textPrimary,
                              fontFamily: 'Inter',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Barra
                        Expanded(
                          flex: 4,
                          child: BarraProgreso(
                            percentage: sl.percentage,
                            fillColor: sl.color,
                            height: 6,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Masa
                        SizedBox(
                          width: 60,
                          child: Text(
                            gStr,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              color: AnalyticsPalette.textPrimary,
                              fontFamily: 'Inter',
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Porcentaje
                        SizedBox(
                          width: 40,
                          child: Text(
                            slPctStr,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              color: AnalyticsPalette.textSecondary,
                              fontFamily: 'Inter',
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AnalyticsPalette.track,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AnalyticsPalette.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabItem(0, 'Material'),
          _buildTabItem(1, 'Categoría'),
          _buildTabItem(2, 'Color'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = tabIndex == index;
    return InkWell(
      onTap: () => onTabChanged(index),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AnalyticsPalette.segmentActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          boxShadow: isSelected ? AnalyticsPalette.cardShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? AnalyticsPalette.textPrimary
                : AnalyticsPalette.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _SimpleDonutPainter extends CustomPainter {
  final List<({String label, double grams, Color color, double percentage})> slices;
  final double totalGrams;

  _SimpleDonutPainter({required this.slices, required this.totalGrams});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 16.0;

    final bgPaint = Paint()
      ..color = AnalyticsPalette.track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (totalGrams <= 0 || slices.isEmpty) return;

    var startAngle = -math.pi / 2;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    for (final slice in slices) {
      final sweepAngle = (slice.grams / totalGrams) * 2 * math.pi;
      if (sweepAngle <= 0.001) continue;

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleDonutPainter oldDelegate) => true;
}
