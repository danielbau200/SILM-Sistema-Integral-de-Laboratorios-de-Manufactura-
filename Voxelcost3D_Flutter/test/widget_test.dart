import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxelcost3d/main.dart';
import 'package:voxelcost3d/theme.dart';
import 'package:voxelcost3d/models.dart';

void main() {
  testWidgets('Verifica login y dashboard con nuevo estilo industrial',
      (WidgetTester tester) async {
    await tester.pumpWidget(const VoxelcostApp());

    // Login screen verification
    expect(find.text('VOXELCOST3D'), findsOneWidget);
    expect(find.text('SISTEMA DE CONTROL DE FABRICACIÓN'), findsOneWidget);
    expect(find.text('ACCEDER AL TALLER'), findsOneWidget);

    // Ingresar credenciales
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));
    await tester.enterText(textFields.at(0), 'admin');
    await tester.enterText(textFields.at(1), 'admin123');

    // Tap en Acceder al taller
    await tester.tap(find.text('ACCEDER AL TALLER'));
    await tester.pumpAndSettle();

    // Al iniciar sesión aparece la bienvenida a pantalla completa
    expect(find.text('¡BIENVENIDO!'), findsOneWidget);

    // Dar clic en el botón de menú de hamburguesa para abrirlo y empujar el panel
    await tester.tap(find.byTooltip('Regresar'));
    await tester.pumpAndSettle();

    // Home screen dashboard verification con menú abierto
    expect(find.text('OPERATIVO'), findsOneWidget);
    expect(find.text('Gestionar Impresiones'), findsOneWidget);
    expect(find.text('Inventario de Materiales'), findsOneWidget);
    expect(find.text('Análisis de Producción'), findsOneWidget);
    expect(find.text('CERRAR SESIÓN'), findsOneWidget);

    // Navegar a Historial Técnico
    await tester.tap(find.text('Gestionar Impresiones'));
    await tester.pumpAndSettle();
    expect(find.text('HISTORIAL TÉCNICO'), findsOneWidget);
    expect(find.text('REGISTROS'), findsOneWidget);
    expect(find.text('TOTAL'), findsOneWidget);
    expect(find.text('PLA'), findsWidgets);
    expect(find.text('PETG'), findsWidgets);

    // Regresar al Home
    await tester.tap(find.byTooltip('Regresar'));
    await tester.pumpAndSettle();
    expect(find.text('OPERATIVO'), findsOneWidget);

    // Navegar a Inventario
    await tester.tap(find.text('Inventario de Materiales'));
    await tester.pumpAndSettle();
    expect(find.text('INVENTARIO DE MATERIALES'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // Barra de búsqueda

    // Regresar al Home
    await tester.tap(find.byTooltip('Regresar'));
    await tester.pumpAndSettle();

    // Navegar a Análisis de Producción
    await tester.tap(find.text('Análisis de Producción'));
    await tester.pumpAndSettle();
    expect(find.text('ANÁLISIS DE PRODUCCIÓN'), findsOneWidget);
    expect(find.text('CONSUMO MENSUAL'), findsOneWidget);
    expect(find.text('PRODUCCIÓN MENSUAL'), findsOneWidget);
  });

  testWidgets('Verifica tokens de color y tema industrial',
      (WidgetTester tester) async {
    final theme = voxelTheme();
    expect(theme.scaffoldBackgroundColor, bgBase);
    expect(theme.colorScheme.primary, accentPetrol);
    expect(theme.colorScheme.secondary, accentAmber);
    expect(theme.colorScheme.surface, surfaceCard);
  });

  test('Verifica PrintRecord con soporte de cantidad y cálculo total de gramos', () {
    final record = PrintRecord(
      id: 1,
      date: DateTime.now().millisecondsSinceEpoch,
      pieceType: 'Soporte Engrane',
      figureCategory: 'Prototipo',
      materials: [
        MaterialData(
          type: 'PLA',
          colorName: 'Negro',
          color: 0xFF111111,
          grams: 30.0,
        ),
      ],
      cantidad: 10,
    );

    expect(record.cantidad, 10);
    expect(record.unitGrams, 30.0);
    expect(record.totalGrams, 300.0);

    // Verificación de serialización toMap y fromMap
    final map = record.toMap();
    expect(map['cantidad'], 10);

    final fromMapRecord = PrintRecord.fromMap(map);
    expect(fromMapRecord.cantidad, 10);
    expect(fromMapRecord.totalGrams, 300.0);

    // Verificación de migración heredada (cantidad ausente o null)
    final legacyMap = Map<String, dynamic>.from(map);
    legacyMap.remove('cantidad');
    final migratedRecord = PrintRecord.fromMap(legacyMap);
    expect(migratedRecord.cantidad, 1);
    expect(migratedRecord.totalGrams, 30.0);

    // Verificación de salvaguarda de mínimo 1
    final invalidQuantityRecord = PrintRecord(
      id: 2,
      date: DateTime.now().millisecondsSinceEpoch,
      pieceType: 'Pieza Test',
      figureCategory: 'Miniatura',
      materials: [
        MaterialData(
          type: 'PETG',
          colorName: 'Rojo',
          color: 0xFFE53935,
          grams: 15.0,
        ),
      ],
      cantidad: 0,
    );
    expect(invalidQuantityRecord.cantidad, 1);
  });
}