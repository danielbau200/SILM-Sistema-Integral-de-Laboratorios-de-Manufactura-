import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxelcost3d/controllers.dart';
import 'package:voxelcost3d/database.dart';
import 'package:voxelcost3d/main.dart';
import 'package:voxelcost3d/theme.dart';
import 'package:voxelcost3d/models.dart';
import 'package:voxelcost3d/screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('Verifica el conmutador y el modo oscuro global',
      (WidgetTester tester) async {
    await tester.pumpWidget(const VoxelcostApp());

    expect(find.text('VOXELCOST3D'), findsOneWidget);
    expect(find.text('ACCEDER AL TALLER'), findsOneWidget);

    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));
    await tester.enterText(textFields.at(0), 'admin');
    await tester.enterText(textFields.at(1), 'admin123');
    await tester.tap(find.text('ACCEDER AL TALLER'));
    await tester.pumpAndSettle();

    expect(find.text('¡BIENVENIDO!'), findsOneWidget);
    await tester.tap(find.byType(SidebarToggleIcon).first);
    await tester.pumpAndSettle();

    expect(find.text('OPERATIVO'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SidebarToggleIcon && widget.color == accentPetrol,
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Activar modo oscuro'), findsOneWidget);

    await tester.tap(find.byTooltip('Activar modo oscuro'));
    await tester.pumpAndSettle();
    expect(bgBase, const Color(0xFF111318));
    expect(surfaceCard, const Color(0xFF1B1E25));
    expect(textPrimary, const Color(0xFFF1F3F6));
    expect(voxelTheme().brightness, Brightness.dark);
    expect(find.byTooltip('Activar modo claro'), findsOneWidget);

    await tester.tap(find.text('Registro de Impresiones'));
    await tester.pumpAndSettle();
    expect(find.text('HISTORIAL TÉCNICO'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
      const Color(0xFF111318),
    );
    await tester.tap(find.byType(SidebarToggleIcon).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Activar modo claro'));
    await tester.pumpAndSettle();
    expect(bgBase, const Color(0xFFF5F5F7));
  });

  testWidgets('Verifica tokens de color y tema industrial',
      (WidgetTester tester) async {
    final theme = voxelTheme();
    expect(theme.scaffoldBackgroundColor, bgBase);
    expect(theme.colorScheme.primary, accentPetrol);
    expect(theme.colorScheme.secondary, accentAmber);
    expect(theme.colorScheme.surface, surfaceCard);
  });

  testWidgets('El análisis de producción se adapta al ancho de pantalla',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final printVm = PrintViewModel(AppDatabase());
    final inventoryVm = InventoryViewModel(AppDatabase());
    addTearDown(printVm.dispose);
    addTearDown(inventoryVm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: voxelTheme(),
        home: AnalyticsScreen(
          vm: printVm,
          inventoryVm: inventoryVm,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ANÁLISIS DE PRODUCCIÓN'), findsOneWidget);
    expect(find.text('MATERIAL CONSUMIDO'), findsOneWidget);
    expect(find.text('PIEZAS FABRICADAS'), findsOneWidget);
    expect(find.text('VALOR EN MATERIAL'), findsNothing);
    expect(find.text('CATEGORÍAS DE USO'), findsOneWidget);
    expect(find.text('IMPRESIONES CON MAYOR CONSUMO'), findsOneWidget);
    expect(find.text('MATERIALES Y COLORES'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('analytics_evolution_card')))
          .width,
      tester
          .getSize(find.byKey(const ValueKey('analytics_category_card')))
          .width,
    );
    expect(
      tester
          .getTopRight(find.byKey(const ValueKey('analytics_category_card')))
          .dx,
      1420,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('analytics_category_card')))
          .height,
      tester
          .getSize(find.byKey(const ValueKey('analytics_evolution_card')))
          .height,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('analytics_top_pieces_card')))
          .width,
      tester
          .getSize(find.byKey(const ValueKey('analytics_material_color_card')))
          .width,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('analytics_top_pieces_card')))
          .height,
      tester
          .getSize(find.byKey(const ValueKey('analytics_material_color_card')))
          .height,
    );
    expect(
      tester.getBottomRight(find.text('Sin datos').last).dy,
      lessThanOrEqualTo(720),
    );
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(900, 1000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1440, 1000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Los datos de impresora quedan arriba de la pieza en todas las pantallas',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final printVm = PrintViewModel(AppDatabase());
    final inventoryVm = InventoryViewModel(AppDatabase());
    addTearDown(printVm.dispose);
    addTearDown(inventoryVm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: voxelTheme(),
        home: PrintFormScreen(vm: printVm, inventoryVm: inventoryVm),
      ),
    );
    await tester.pumpAndSettle();

    final printerPanel = find.byKey(const ValueKey('printer_info_panel'));
    expect(
        find.byKey(const ValueKey('printer_select_dropdown')), findsOneWidget);
    expect(tester.getTopLeft(printerPanel).dx, lessThan(100));
    expect(
      tester.getTopLeft(find.text('DATOS DE LA IMPRESORA')).dy,
      lessThan(
        tester.getTopLeft(find.text('INFORMACIÓN DE LA PIEZA')).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.text('INFORMACIÓN DE LA PIEZA')).dy,
      lessThan(
        tester.getTopLeft(find.text('MATERIALES UTILIZADOS')).dy,
      ),
    );
    expect(tester.takeException(), isNull);

    expect(
        find.byKey(const ValueKey('material_combination_card')), findsNothing);
    final combinationToggle =
        find.byKey(const ValueKey('material_combination_toggle'));

    final firstGrams = find.byKey(const ValueKey('material_grams_0'));
    await tester.ensureVisible(firstGrams);
    await tester.enterText(firstGrams, '12.5');
    await tester.pump();

    final addMaterialButton = find.text('AGREGAR OTRO MATERIAL');
    await tester.ensureVisible(addMaterialButton);
    await tester.tap(addMaterialButton);
    await tester.pumpAndSettle();
    final secondGrams = find.byKey(const ValueKey('material_grams_1'));
    await tester.ensureVisible(secondGrams);
    await tester.enterText(secondGrams, '7.5');
    await tester.pump();

    // Verificamos que no existe el campo de cantidad de piezas (eliminado por nuevo flujo)
    expect(find.byKey(const ValueKey('print_quantity_field')), findsNothing);

    // Verificamos el tope de 60 minutos en el tiempo de impresión
    final minutesField = find.byKey(const ValueKey('print_minutes_field'));
    await tester.ensureVisible(minutesField);
    await tester.enterText(minutesField, '75');
    await tester.pump();
    expect(find.text('60'), findsOneWidget);

    await tester.ensureVisible(combinationToggle);
    await tester.tap(combinationToggle);
    await tester.pumpAndSettle();
    expect(find.text('COMBINACIÓN DE MATERIAL Y COLORES'), findsOneWidget);
    expect(find.text('MATERIAL'), findsOneWidget);
    expect(find.text('COLOR'), findsOneWidget);
    expect(find.text('GRAMOS'), findsOneWidget);
    expect(find.text('12.5 g'), findsOneWidget);
    expect(find.text('7.5 g'), findsOneWidget);
    expect(find.text('20.0 g / pieza'), findsOneWidget);
    expect(find.text('1 impresión'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(combinationToggle);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('material_combination_card')), findsNothing);

    await tester.drag(find.byType(ListView).last, const Offset(0, 2000));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(800, 1100);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(printerPanel).dx, lessThan(100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('El formulario de bobinas omite costos y ocupa todo el ancho',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final vm = InventoryViewModel(AppDatabase())
      ..materialCatalog = [MaterialCatalogItem('PLA', false)];
    addTearDown(vm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: voxelTheme(),
        home: AddProductScreen(vm: vm),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3. CAPACIDAD Y PESAJE'), findsOneWidget);
    expect(find.text('4. PARÁMETROS TÉCNICOS Y UBICACIÓN'), findsNothing);
    expect(find.text('5. PARÁMETROS TÉCNICOS Y UBICACIÓN'), findsNothing);
    expect(find.text('4. COSTOS Y PRECIOS'), findsNothing);
    expect(find.text('Precio de compra de la bobina'), findsNothing);
    expect(find.text('Costo unitario calculado:'), findsNothing);
    expect(tester.getSize(find.byType(ListView).last).width, 1200);

    final colorNameField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Ej: Rojo Carmesí, Gris Galáctico...',
    );
    await tester.ensureVisible(colorNameField);
    await tester.enterText(colorNameField, 'Oro');
    await tester.pump();
    final preview = tester.widget<KeyedSubtree>(
      find.byKey(const ValueKey('product_color_preview')),
    );
    final previewCircle = preview.child as Container;
    expect(
      (previewCircle.decoration! as BoxDecoration).color,
      const Color(0xFFD4AF37),
    );
  });

  testWidgets(
      'El pedido conserva el inventario y despliega el formulario nuevo',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final vm = InventoryViewModel(AppDatabase());
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        home: MaterialOrderScreen(
          inventoryVm: vm,
          onToggleMenu: () {},
          onHoverMenu: () {},
          isPinned: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    vm.inventoryItems = [
      InventoryItem(
        material: 'PLA',
        color: 'Negro',
        stockInicial: 1000,
        stockActual: 150,
      ),
      InventoryItem(
        material: 'PETG',
        color: 'Azul',
        stockInicial: 1000,
        stockActual: 0,
      ),
      InventoryItem(
        material: 'ABS',
        color: 'Blanco',
        stockInicial: 1000,
        stockActual: 850,
      ),
    ];
    vm.notifyListeners();
    await tester.pumpAndSettle();

    expect(find.text('MATERIALES POR PEDIR'), findsNothing);
    expect(find.text('Lista de pedido'), findsOneWidget);
    expect(find.text('Aún no hay pedidos'), findsOneWidget);
    expect(find.text('PLA'), findsNothing);
    expect(find.text('PETG'), findsNothing);
    expect(find.text('ABS'), findsNothing);
    expect(find.text('Nuevo pedido'), findsOneWidget);
    expect(find.byType(SidebarToggleIcon), findsOneWidget);
    expect(find.text('Link de la página donde se encontró el material'),
        findsNothing);

    await tester.tap(find.text('Nuevo pedido'));
    await tester.pump();
    expect(find.text('Link de la página donde se encontró el material'),
        findsOneWidget);
    expect(find.text('Material'), findsOneWidget);
    expect(find.text('Color del filamento'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Material').first).dy,
      tester.getTopLeft(find.text('Color del filamento').first).dy,
    );
    expect(
      tester.getTopLeft(find.text('Material').first).dy,
      tester.getTopLeft(find.text('Peso del carrete').first).dy,
    );

    final firstOrderLink = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.key is ValueKey &&
          (widget.key! as ValueKey).value.toString().startsWith('order_link_'),
    );
    await tester.enterText(firstOrderLink, 'https://example.com/product');
    expect(find.text('Agregar otro pedido'), findsOneWidget);
    expect(find.text('Datos Combinados del Material'), findsOneWidget);
    expect(find.text('Pedido 1'), findsOneWidget);
    expect(find.byTooltip('Agregar otro pedido'), findsOneWidget);
    final orderLinks = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.key is ValueKey &&
          (widget.key! as ValueKey).value.toString().startsWith('order_link_'),
    );
    final orderDraftId =
        (tester.widget<TextField>(orderLinks.first).key! as ValueKey)
            .value
            .toString()
            .replaceFirst('order_link_', '');
    final orderUrgencyDropdown = find.byKey(
      ValueKey('urgency_order_$orderDraftId'),
    );
    expect(tester.getSize(orderUrgencyDropdown).width, 400);
    final orderUrgencyType = find.byKey(
      ValueKey('order_urgency_type_$orderDraftId'),
    );
    final orderUrgencyDetails = find.byKey(
      ValueKey('order_urgency_details_$orderDraftId'),
    );
    final orderCost = find.byKey(ValueKey('order_cost_$orderDraftId'));
    expect(
      tester.getSize(orderUrgencyType).width,
      tester.getSize(orderUrgencyDetails).width,
    );
    expect(tester.getSize(orderUrgencyType).width, lessThan(500));
    expect(
      tester
          .getSize(find.byKey(ValueKey('order_cost_container_$orderDraftId')))
          .width,
      220,
    );
    expect(
      tester.getTopLeft(orderCost).dy,
      greaterThan(tester.getBottomRight(orderUrgencyDetails).dy),
    );
    expect(orderLinks, findsOneWidget);
    expect(find.byTooltip('Abrir página web'), findsOneWidget);
    expect(
      tester.widget<TextField>(orderLinks.first).controller!.text,
      'https://example.com/product',
    );

    expect(find.text('Urgencia en el laboratorio'), findsNWidgets(5));
    expect(find.text('Tipo de urgencia'), findsOneWidget);
    expect(find.text('Urgencia en texto'), findsNWidgets(2));
    expect(find.text('Peso usado (opcional)'), findsNothing);
    expect(find.text('Consumible y peso'), findsNothing);
    final urgencySectionY = tester
        .getTopLeft(find.byKey(ValueKey('order_urgency_type_$orderDraftId')))
        .dy;
    final consumableSectionY =
        tester.getTopLeft(find.text('Consumibles').first).dy;
    expect(urgencySectionY, lessThan(consumableSectionY));

    final addConsumable = find.text('Agregar otro consumible').first;
    await tester.scrollUntilVisible(
      addConsumable,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(addConsumable).dy,
      greaterThan(
        tester
            .getBottomRight(
              find.byKey(ValueKey('consumables_panel_$orderDraftId')),
            )
            .dy,
      ),
    );
    await tester.tap(addConsumable);
    await tester.pumpAndSettle();
    expect(find.text('Consumible 1'), findsOneWidget);
    expect(find.text('Consumible 2'), findsOneWidget);
    expect(find.byTooltip('Quitar consumible'), findsOneWidget);
    expect(find.text('Urgencia en el laboratorio'), findsNWidgets(7));
    expect(find.text('Tipo de urgencia'), findsNWidgets(2));
    expect(find.text('Urgencia en texto'), findsNWidgets(3));
    final consumableLinkLabel =
        find.text('Link de donde se encontró el consumible').first;
    final firstConsumableLabel = find.text('Consumible 1');
    expect(
      tester.getTopLeft(consumableLinkLabel).dy,
      lessThan(tester.getTopLeft(firstConsumableLabel).dy),
    );
    final firstConsumableDropdown = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButtonFormField<String> &&
          widget.key is ValueKey &&
          (widget.key! as ValueKey)
              .value
              .toString()
              .startsWith('consumable_dropdown_') &&
          (widget.key! as ValueKey).value.toString().endsWith('_0'),
    );
    expect(tester.getSize(firstConsumableDropdown).width, 426);
    final firstConsumableCost =
        find.byKey(ValueKey('consumable_cost_${orderDraftId}_0'));
    expect(firstConsumableCost, findsOneWidget);
    final firstConsumableUrgency = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButtonFormField<String> &&
          widget.key is ValueKey &&
          (widget.key! as ValueKey)
              .value
              .toString()
              .startsWith('urgency_consumable_') &&
          (widget.key! as ValueKey).value.toString().endsWith('_0'),
    );
    expect(
      tester.getSize(firstConsumableUrgency).width,
      tester.getSize(orderUrgencyDropdown).width,
    );
    final firstConsumableUrgencyType =
        find.byKey(const ValueKey('consumable_urgency_type_0'));
    final firstConsumableUrgencyDetails =
        find.byKey(const ValueKey('consumable_urgency_details_0'));
    expect(
      tester
          .getSize(
            find.byKey(
              ValueKey('consumable_cost_container_${orderDraftId}_0'),
            ),
          )
          .width,
      295,
    );
    expect(
      tester.getTopLeft(firstConsumableCost).dy,
      greaterThan(
        tester.getBottomRight(firstConsumableUrgencyDetails).dy,
      ),
    );
    expect(
      tester.getSize(firstConsumableUrgencyType).width,
      tester.getSize(firstConsumableUrgencyDetails).width,
    );
    expect(
      tester.getSize(firstConsumableUrgencyType).width,
      tester.getSize(orderUrgencyType).width,
    );

    final secondConsumable = find.byWidgetPredicate((widget) {
      if (widget is! DropdownButtonFormField<String> ||
          widget.key is! ValueKey) {
        return false;
      }
      final key = (widget.key! as ValueKey).value.toString();
      return key.startsWith('consumable_dropdown_') && key.endsWith('_1');
    });
    await tester.ensureVisible(secondConsumable);
    await tester.tap(secondConsumable);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otro (escribir)').last);
    await tester.pumpAndSettle();
    expect(find.text('Escribe el consumible'), findsOneWidget);
    final secondConsumableCost =
        find.byKey(const ValueKey('consumable_cost_0_1'));
    expect(secondConsumableCost, findsOneWidget);
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey('consumable_cost_container_0_1'),
            ),
          )
          .width,
      295,
    );
    expect(
      tester.getTopLeft(secondConsumableCost).dy,
      greaterThan(
        tester
            .getBottomRight(
              find.byKey(const ValueKey('consumable_urgency_details_1')),
            )
            .dy,
      ),
    );
    expect(
      find.text('Link de donde se encontró el consumible'),
      findsNWidgets(2),
    );
    await tester.enterText(
      find.byKey(const ValueKey('consumable_link_0_1')),
      'consumables.example.com/nozzle',
    );
    await tester.enterText(
      find.byKey(const ValueKey('consumable_cost_0_1')),
      '24.50',
    );
    tester.testTextInput.hide();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    final colorDropdown = find.byType(DropdownButtonFormField<String>).at(1);
    await tester.ensureVisible(colorDropdown);
    await tester.pumpAndSettle();
    await tester.tap(colorDropdown);
    await tester.pumpAndSettle();
    expect(find.text('Marrón Van Dyke'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('filament_palette_swatch_marrón van dyke')),
      findsOneWidget,
    );
    await tester.tap(find.text('Marrón Van Dyke'));
    await tester.pump();
    expect(
        find.byKey(const ValueKey('selected_filament_swatch')), findsOneWidget);

    await tester.ensureVisible(colorDropdown);
    await tester.pumpAndSettle();
    await tester.tap(colorDropdown);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Oro'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Oro'));
    await tester.pump();
    final goldSwatch = tester.widget<Container>(
      find.byKey(const ValueKey('selected_filament_swatch')),
    );
    expect(
      (goldSwatch.decoration! as BoxDecoration).color,
      const Color(0xFFD4AF37),
    );

    await tester.ensureVisible(colorDropdown);
    await tester.pumpAndSettle();
    await tester.tap(colorDropdown);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Silver'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Silver'));
    await tester.pump();
    final silverSwatch = tester.widget<Container>(
      find.byKey(const ValueKey('selected_filament_swatch')),
    );
    expect(
      (silverSwatch.decoration! as BoxDecoration).color,
      const Color(0xFFC0C0C0),
    );

    await tester.ensureVisible(colorDropdown);
    await tester.pumpAndSettle();
    await tester.tap(colorDropdown);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Agregar otro color'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Agregar otro color'));
    await tester.pump();
    final customColorField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Ej. Azul marino o #123ABC',
    );
    await tester.ensureVisible(customColorField);
    await tester.enterText(customColorField, 'oro');
    await tester.pump();
    final namedColorPreview = tester.widget<Container>(
      find.byKey(const ValueKey('filament_preview_swatch')),
    );
    expect(
      (namedColorPreview.decoration! as BoxDecoration).color,
      const Color(0xFFD4AF37),
    );
    await tester.enterText(customColorField, '#123ABC');
    await tester.pump();
    final liveColorPreview = tester.widget<Container>(
      find.byKey(const ValueKey('filament_preview_swatch')),
    );
    expect(
      (liveColorPreview.decoration! as BoxDecoration).color,
      const Color(0xFF123ABC),
    );
    await tester.ensureVisible(colorDropdown);
    await tester.pumpAndSettle();
    await tester.tap(colorDropdown);
    await tester.pumpAndSettle();
    expect(find.text('#123ABC'), findsNWidgets(3));
    await tester.tap(find.text('#123ABC').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('selected_filament_swatch')),
      findsOneWidget,
    );

    final urgencyDropdown = find
        .byWidgetPredicate(
          (widget) =>
              widget is DropdownButtonFormField<String> &&
              widget.key is ValueKey &&
              (widget.key! as ValueKey)
                  .value
                  .toString()
                  .startsWith('urgency_order_'),
        )
        .first;
    await tester.ensureVisible(urgencyDropdown);
    await tester.pumpAndSettle();
    await tester.tap(urgencyDropdown);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('Rojo').last).style?.color,
      Theme.of(tester.element(urgencyDropdown)).colorScheme.onSurface,
    );
    await tester.tap(find.text('Rojo').last);
    await tester.pump();
    expect(find.text('Tipo de urgencia'), findsNWidgets(2));
    expect(find.text('Urgencia en texto'), findsNWidgets(3));
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(urgencyDropdown)
          .decoration
          .fillColor,
      const Color(0xFFDC2626),
    );

    await tester.tap(urgencyDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amarillo').last);
    await tester.pump();
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(urgencyDropdown)
          .decoration
          .fillColor,
      const Color(0xFFFACC15),
    );
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: urgencyDropdown,
              matching: find.text('Amarillo'),
            ),
          )
          .style
          ?.color,
      Colors.white,
    );

    await tester.tap(urgencyDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verde').last);
    await tester.pump();
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(urgencyDropdown)
          .decoration
          .fillColor,
      const Color(0xFF15803D),
    );
    final secondConsumableUrgency = find
        .byWidgetPredicate(
          (widget) =>
              widget is DropdownButtonFormField<String> &&
              widget.key is ValueKey &&
              (widget.key! as ValueKey)
                  .value
                  .toString()
                  .startsWith('urgency_consumable_'),
        )
        .last;
    await tester.ensureVisible(secondConsumableUrgency);
    await tester.pumpAndSettle();
    await tester.tap(secondConsumableUrgency);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amarillo').last);
    await tester.pump();
    expect(find.text('Tipo de urgencia'), findsNWidgets(2));
    expect(find.text('Urgencia en texto'), findsNWidgets(3));

    final addAnotherOrder = find.byKey(const ValueKey('add_order_draft_0'));
    await tester.ensureVisible(addAnotherOrder);
    await tester.pumpAndSettle();
    await tester.tap(addAnotherOrder);
    await tester.pumpAndSettle();
    expect(find.text('Pedido 2'), findsOneWidget);
    expect(orderLinks, findsNWidgets(2));
    expect(find.byKey(const ValueKey('order_draft_template')), findsOneWidget);
    expect(find.text('Urgencia en el laboratorio'), findsNWidgets(10));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String> &&
            widget.key is ValueKey &&
            (widget.key! as ValueKey).value.toString().startsWith('urgency_'),
      ),
      findsNWidgets(4),
    );
    expect(find.text('Tipo de urgencia'), findsNWidgets(2));
    expect(find.text('Urgencia en texto'), findsNWidgets(4));

    final secondUrgencyDropdown = find
        .byWidgetPredicate(
          (widget) =>
              widget is DropdownButtonFormField<String> &&
              widget.key is ValueKey &&
              (widget.key! as ValueKey)
                  .value
                  .toString()
                  .startsWith('urgency_order_'),
        )
        .last;
    await tester.ensureVisible(secondUrgencyDropdown);
    await tester.pumpAndSettle();
    await tester.tap(secondUrgencyDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amarillo').last);
    await tester.pump();
    expect(find.text('Tipo de urgencia'), findsNWidgets(2));
    expect(find.text('Urgencia en texto'), findsNWidgets(4));
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(urgencyDropdown)
          .initialValue,
      'Verde',
    );
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(secondConsumableUrgency)
          .initialValue,
      'Amarillo',
    );
    expect(find.text('Consumibles'), findsOneWidget);
    expect(find.text('Costo del material'), findsNothing);
    expect(find.byKey(ValueKey('order_cost_$orderDraftId')), findsOneWidget);
    expect(find.text('Agregar a la tabla'), findsOneWidget);
    expect(
      tester.widget<TextField>(orderLinks.first).controller!.text,
      'https://example.com/product',
    );

    final removeSecondOrder =
        find.byKey(const ValueKey('remove_order_draft_1'));
    expect(removeSecondOrder, findsOneWidget);
    expect(
      tester.widget<IconButton>(removeSecondOrder).tooltip,
      'Quitar pedido',
    );
    expect(
      tester.widget<IconButton>(removeSecondOrder).icon,
      isA<Icon>().having(
        (icon) => icon.icon,
        'icon',
        Icons.remove_circle_outline_rounded,
      ),
    );
    await tester.ensureVisible(removeSecondOrder);
    await tester.pumpAndSettle();
    await tester.tap(removeSecondOrder);
    await tester.pumpAndSettle();
    expect(find.text('Pedido 2'), findsNothing);
    expect(orderLinks, findsOneWidget);
    expect(find.byKey(const ValueKey('remove_order_draft_1')), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('consumable_urgency_type_0')),
      'Reposición del consumible principal',
    );
    await tester.enterText(
      find.byKey(const ValueKey('consumable_urgency_details_0')),
      'Se requiere para continuar',
    );
    await tester.enterText(
      find.byKey(const ValueKey('consumable_urgency_type_1')),
      'Reposición de la boquilla',
    );
    await tester.enterText(
      find.byKey(const ValueKey('consumable_urgency_details_1')),
      'La boquilla actual está desgastada',
    );
    await tester.enterText(
      find.byKey(const ValueKey('consumable_manual_0_1')),
      'Boquilla de 0.4 mm',
    );
    await tester.enterText(
      find.byKey(ValueKey('order_urgency_type_$orderDraftId')),
      'Reposición urgente',
    );
    await tester.enterText(
      find.byKey(ValueKey('order_urgency_details_$orderDraftId')),
      'Filamento necesario para la impresión',
    );
    await tester.enterText(
      find.byKey(ValueKey('order_cost_$orderDraftId')),
      '525.75',
    );
    final materialDropdown = find.byKey(const ValueKey('order_material_0'));
    await tester.scrollUntilVisible(
      materialDropdown,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(materialDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('PLA').last);
    await tester.pumpAndSettle();
    final submitOrder = find.byKey(const ValueKey('submit_order_0'));
    await tester.ensureVisible(submitOrder);
    await tester.pumpAndSettle();
    await tester.tap(submitOrder);
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    final savedOrders = jsonDecode(
      preferences.getString('pedido_materiales_widget_v1')!,
    ) as Map<String, dynamic>;
    final savedOrder = (savedOrders['orders'] as List).first as Map;
    expect(find.byKey(const ValueKey('material_orders_list')), findsOneWidget);
    expect(find.text('PLA'), findsOneWidget);
    expect(find.text('example.com'), findsOneWidget);
    expect(
      find.byKey(
        ValueKey('order_consumable_item_${savedOrder['id']}_0'),
      ),
      findsOneWidget,
    );
    expect(savedOrder['urgency'], 'Verde');
    expect(savedOrder['cost'], 525.75);
    final urgencyCell = find.byKey(
      ValueKey('order_urgency_cell_${savedOrder['id']}'),
    );
    expect(tester.getSize(urgencyCell).width, 300);
    expect(
      tester
          .getTopLeft(
            find.byKey(
              ValueKey('order_consumable_item_${savedOrder['id']}_0'),
            ),
          )
          .dy,
      greaterThan(tester.getBottomRight(urgencyCell).dy),
    );
    expect(
      find.byTooltip(
        'Verde · Reposición urgente: Filamento necesario para la impresión',
      ),
      findsOneWidget,
    );
    final savedRequests = savedOrder['consumableRequests'] as List;
    expect(savedRequests, hasLength(1));
    expect(savedRequests.single['name'], 'Boquilla de 0.4 mm');
    expect(savedRequests.single['cost'], 24.5);
    expect(
      savedRequests.single['link'],
      'https://consumables.example.com/nozzle',
    );
    expect(savedRequests.single['urgency'], 'Amarillo');
    expect(
      savedRequests.single['urgencyDetails'],
      'La boquilla actual está desgastada',
    );
    expect(
        savedOrder['urgencyDetails'], 'Filamento necesario para la impresión');

    final editOrderButton = find.byKey(
      ValueKey('edit_order_${savedOrder['id']}'),
    );
    await tester.ensureVisible(editOrderButton);
    await tester.pumpAndSettle();
    await tester.tap(editOrderButton);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('edit_order_link'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('edit_order_material'))).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('edit_order_urgency'))).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const ValueKey('edit_order_weight'))).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('edit_order_cost'))).dy,
      greaterThan(
        tester
            .getBottomRight(
              find.byKey(const ValueKey('edit_order_urgency_details')),
            )
            .dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('edit_order_cost'))).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('edit_consumable_row_0')))
            .dy,
      ),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('edit_consumable_link_0')))
          .dy,
      lessThan(tester
          .getTopLeft(
            find.byKey(const ValueKey('edit_consumable_name_0')),
          )
          .dy),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('edit_consumable_name_0')))
          .dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('edit_consumable_urgency_0')))
            .dy,
      ),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('edit_consumable_urgency_0')))
          .dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('edit_consumable_details_0')))
            .dy,
      ),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('edit_consumable_cost_0')))
          .dy,
      greaterThan(
        tester
            .getBottomRight(
              find.byKey(const ValueKey('edit_consumable_details_0')),
            )
            .dy,
      ),
    );
    final orderCostWidth =
        tester.getSize(find.byKey(const ValueKey('edit_order_cost'))).width;
    final consumableCostWidth = tester
        .getSize(find.byKey(const ValueKey('edit_consumable_cost_0')))
        .width;
    expect(orderCostWidth, closeTo(140, 1));
    expect(consumableCostWidth, closeTo(140, 1));
    final orderUrgencySize =
        tester.getSize(find.byKey(const ValueKey('edit_order_urgency')));
    final consumableUrgencySize = tester.getSize(
      find.byKey(const ValueKey('edit_consumable_urgency_0')),
    );
    expect(consumableUrgencySize.width, orderUrgencySize.width);
    expect(consumableUrgencySize.height, orderUrgencySize.height);
    expect(orderUrgencySize.width, closeTo(300, 1));

    Future<void> editField(Key key, String value) async {
      final field = find.byKey(key);
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
    }

    await editField(
      const ValueKey('edit_order_link'),
      'https://store.example.com/updated',
    );
    await editField(const ValueKey('edit_order_material'), 'PETG');
    await editField(const ValueKey('edit_order_color'), 'Azul marino');
    await editField(const ValueKey('edit_order_weight'), '1500 g');
    await editField(
        const ValueKey('edit_order_urgency_type'), 'Compra planeada');
    await editField(
      const ValueKey('edit_order_urgency_details'),
      'Se actualizó la prioridad del material',
    );
    await editField(const ValueKey('edit_order_cost'), '875.50');
    await editField(
      const ValueKey('edit_consumable_name_0'),
      'Boquilla de 0.6 mm',
    );
    await editField(
      const ValueKey('edit_consumable_link_0'),
      'https://store.example.com/nozzle-06',
    );
    await editField(const ValueKey('edit_consumable_cost_0'), '31.75');
    await editField(
      const ValueKey('edit_consumable_details_0'),
      'La nueva boquilla se requiere para PETG',
    );
    final editUrgency = find.byKey(const ValueKey('edit_order_urgency'));
    await tester.ensureVisible(editUrgency);
    await tester.tap(editUrgency);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rojo').last);
    await tester.pumpAndSettle();
    final saveEdits = find.byKey(const ValueKey('save_order_edits'));
    await tester.ensureVisible(saveEdits);
    await tester.tap(saveEdits);
    await tester.pumpAndSettle();

    final updatedSavedOrders = jsonDecode(
      preferences.getString('pedido_materiales_widget_v1')!,
    ) as Map<String, dynamic>;
    final updatedSavedOrder =
        (updatedSavedOrders['orders'] as List).first as Map;
    expect(updatedSavedOrder['link'], 'https://store.example.com/updated');
    expect(updatedSavedOrder['material'], 'PETG');
    expect(updatedSavedOrder['color'], 'Azul marino');
    expect(updatedSavedOrder['spoolGrams'], 1500);
    expect(updatedSavedOrder['urgency'], 'Rojo');
    expect(updatedSavedOrder['urgencyType'], 'Compra planeada');
    expect(updatedSavedOrder['urgencyDetails'],
        'Se actualizó la prioridad del material');
    expect(updatedSavedOrder['cost'], 875.5);
    final updatedRequests = updatedSavedOrder['consumableRequests'] as List;
    expect(updatedRequests.single['name'], 'Boquilla de 0.6 mm');
    expect(
      updatedRequests.single['link'],
      'https://store.example.com/nozzle-06',
    );
    expect(updatedRequests.single['cost'], 31.75);
    expect(updatedRequests.single['urgency'], 'Amarillo');
    expect(
      updatedRequests.single['urgencyDetails'],
      'La nueva boquilla se requiere para PETG',
    );

    final closeOrderForm = find.text('Cerrar formulario de pedido');
    await tester.ensureVisible(closeOrderForm);
    await tester.pumpAndSettle();
    await tester.tap(closeOrderForm);
    await tester.pump();
    expect(find.text('Link de la página donde se encontró el material'),
        findsNothing);
  });

  test('Verifica PrintRecord con soporte de cantidad y cálculo total de gramos',
      () {
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
      printerName: 'Bambu Lab A1',
      printerCount: 3,
      hasMaterialCombination: true,
      cantidad: 10,
    );

    expect(record.cantidad, 10);
    expect(record.unitGrams, 30.0);
    expect(record.totalGrams, 300.0);

    // Verificación de serialización toMap y fromMap
    final map = record.toMap();
    expect(map['cantidad'], 10);
    expect(map['printerName'], 'Bambu Lab A1');
    expect(map['printerCount'], 3);
    expect(map['hasMaterialCombination'], isTrue);

    final fromMapRecord = PrintRecord.fromMap(map);
    expect(fromMapRecord.cantidad, 10);
    expect(fromMapRecord.printerName, 'Bambu Lab A1');
    expect(fromMapRecord.printerCount, 3);
    expect(fromMapRecord.hasMaterialCombination, isTrue);
    expect(fromMapRecord.totalGrams, 300.0);

    // Verificación de migración heredada (cantidad ausente o null)
    final legacyMap = Map<String, dynamic>.from(map);
    legacyMap.remove('cantidad');
    legacyMap.remove('printerName');
    legacyMap.remove('printerCount');
    legacyMap.remove('hasMaterialCombination');
    final migratedRecord = PrintRecord.fromMap(legacyMap);
    expect(migratedRecord.cantidad, 1);
    expect(migratedRecord.printerName, isNull);
    expect(migratedRecord.printerCount, 1);
    expect(migratedRecord.hasMaterialCombination, isFalse);
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

    final cappedPrinterRecord = PrintRecord(
      date: DateTime.now().millisecondsSinceEpoch,
      pieceType: 'Pieza Test',
      figureCategory: 'Miniatura',
      materials: const [],
      printerCount: 101,
    );
    expect(cappedPrinterRecord.printerCount, 100);
  });

  test(
      'Verifica PrintRecord con datos de solicitante, número de control/empleado y tiempo de impresión',
      () {
    final record = PrintRecord(
      id: 5,
      date: DateTime.now().millisecondsSinceEpoch,
      pieceType: 'Soporte de Sensor Ultrasónico',
      figureCategory: 'Pieza Funcional',
      materials: [
        MaterialData(
          type: 'PLA',
          colorName: 'Azul',
          color: 0xFF1976D2,
          grams: 45.5,
        ),
      ],
      printerName: 'Bambulab A1 Mini Combo',
      printerCount: 1,
      cantidad: 2,
      requesterType: 'Estudiante',
      requesterName: 'Juan Pérez Morales',
      requesterId: '21120456',
      printTime: '3h 15m',
      notes: 'Pieza para proyecto final de Mecatrónica',
    );

    expect(record.requesterType, 'Estudiante');
    expect(record.requesterName, 'Juan Pérez Morales');
    expect(record.requesterId, '21120456');
    expect(record.printTime, '3h 15m');
    expect(record.totalGrams, 91.0);

    final map = record.toMap();
    expect(map['requesterType'], 'Estudiante');
    expect(map['requesterName'], 'Juan Pérez Morales');
    expect(map['requesterId'], '21120456');
    expect(map['printTime'], '3h 15m');

    final deserialized = PrintRecord.fromMap(map);
    expect(deserialized.requesterType, 'Estudiante');
    expect(deserialized.requesterName, 'Juan Pérez Morales');
    expect(deserialized.requesterId, '21120456');
    expect(deserialized.printTime, '3h 15m');
    expect(deserialized.pieceType, 'Soporte de Sensor Ultrasónico');
  });

  test('Verifica PrintRecord con nombre del proyecto y deserialización', () {
    final record = PrintRecord(
      id: 10,
      date: DateTime.now().millisecondsSinceEpoch,
      pieceType: 'brazo_robotico_v3.stl',
      projectName: 'Proyecto Automatización SILM',
      figureCategory: 'Prototipo',
      materials: [
        MaterialData(
          type: 'PLA',
          colorName: 'Negro',
          color: 0xFF111111,
          grams: 25.0,
        ),
      ],
      printerName: 'Bambu Lab X1-Carbon',
      printerCount: 1,
      cantidad: 1,
      requesterType: 'Docente',
      requesterName: 'Dr. Roberto Mendoza',
      requesterId: 'DOC-5012',
      printTime: '1h 45m',
    );

    expect(record.projectName, 'Proyecto Automatización SILM');
    expect(record.pieceType, 'brazo_robotico_v3.stl');
    expect(record.cantidad, 1);

    final map = record.toMap();
    expect(map['projectName'], 'Proyecto Automatización SILM');
    expect(map['pieceType'], 'brazo_robotico_v3.stl');

    final copy = PrintRecord.fromMap(map);
    expect(copy.projectName, 'Proyecto Automatización SILM');
    expect(copy.pieceType, 'brazo_robotico_v3.stl');
  });

  testWidgets(
      'Verifica filtro por semestres académicos en el análisis de producción',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final printVm = PrintViewModel(AppDatabase());
    final inventoryVm = InventoryViewModel(AppDatabase());
    addTearDown(printVm.dispose);
    addTearDown(inventoryVm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: voxelTheme(),
        home: AnalyticsScreen(
          vm: printVm,
          inventoryVm: inventoryVm,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sem. actual'), findsOneWidget);
    expect(find.text('Sem. anterior'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);

    // Conmutar a Semestre Anterior
    await tester.tap(find.text('Sem. anterior'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Conmutar a Historial
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Seleccionar opción de Historial para cerrar el popup
    if (find.text('Historial semestral completo').evaluate().isNotEmpty) {
      await tester.tap(find.text('Historial semestral completo'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    // Conmutar a Semestre Actual
    await tester.tap(find.text('Sem. actual'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'ExportScreen permite filtrar por semestres y en inventario por material y bajo stock',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final printVm = PrintViewModel(AppDatabase());
    final inventoryVm = InventoryViewModel(AppDatabase());
    addTearDown(printVm.dispose);
    addTearDown(inventoryVm.dispose);

    // Agregar items al inventario: uno con bajo stock y otro normal
    inventoryVm.inventoryItems = [
      InventoryItem(
        id: 'item_1',
        material: 'PLA',
        color: 'Rojo',
        stockActual: 100,
        stockInicial: 1000, // 10% -> Bajo stock
      ),
      InventoryItem(
        id: 'item_2',
        material: 'PETG',
        color: 'Azul',
        stockActual: 800,
        stockInicial: 1000, // 80% -> Normal
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: voxelTheme(),
        home: ExportScreen(
          vm: printVm,
          inventoryVm: inventoryVm,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verificar selector de periodos / semestres en pestaña Impresiones
    expect(find.byType(DropdownButton<String>), findsOneWidget);
    // Abrir dropdown de periodos
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    expect(find.textContaining('Semestre Actual'), findsWidgets);
    expect(find.textContaining('Semestre Anterior'), findsWidgets);

    // Seleccionar Semestre Anterior
    await tester.tap(find.textContaining('Semestre Anterior').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 2. Cambiar a la pestaña de Inventario
    await tester.tap(find.textContaining('INVENTARIO'));
    await tester.pumpAndSettle();

    // Deben encontrarse los dropdowns de material y bajo stock
    expect(find.text('Todos los materiales'), findsOneWidget);
    expect(find.text('Todo el stock'), findsOneWidget);
    expect(find.textContaining('PLA - Rojo'), findsOneWidget);
    expect(find.textContaining('PETG - Azul'), findsOneWidget);

    // Filtrar por Bajo stock
    await tester.tap(find.text('Todo el stock'));
    await tester.pumpAndSettle();
    expect(find.text('Bajo stock (≤ 20%)'), findsWidgets);

    await tester.tap(find.text('Bajo stock (≤ 20%)').last);
    await tester.pumpAndSettle();

    // Solo debe mostrarse el item con bajo stock (PLA)
    expect(find.textContaining('PLA - Rojo'), findsOneWidget);
    expect(find.textContaining('PETG - Azul'), findsNothing);

    // Filtrar por tipo de material: PETG
    await tester.tap(find.text('Todos los materiales'));
    await tester.pumpAndSettle();
    expect(find.text('PETG'), findsWidgets);

    await tester.tap(find.text('PETG').last);
    await tester.pumpAndSettle();

    // Ninguno cumple ambos criterios (PETG tiene stock normal)
    expect(find.textContaining('No hay materiales en este filtro'),
        findsOneWidget);

    // Cambiar filtro de stock de nuevo a 'Todo el stock'
    await tester.tap(find.text('Bajo stock (≤ 20%)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todo el stock').last);
    await tester.pumpAndSettle();

    // Ahora sí se muestra PETG
    expect(find.textContaining('PETG - Azul'), findsOneWidget);
    expect(find.textContaining('PLA - Rojo'), findsNothing);
  });
}
