import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'institutional_settings.dart';
import 'theme.dart' show SidebarToggleIcon, darkAppBar, voxelColorPalette;
import 'word_inventory_exporter.dart';

({String type, String details}) _parseUrgencyDescription(String value) {
  final description = value.trim();
  final separator = description.indexOf(',');
  if (separator < 0) {
    return (type: 'Urgencia', details: description);
  }
  final type = description.substring(0, separator).trim();
  final details = description.substring(separator + 1).trim();
  if (type.isEmpty || details.isEmpty) {
    return (type: 'Urgencia', details: description);
  }
  return (type: type, details: details);
}

String _joinUrgencyDescription(String type, String details) =>
    details.trim().isEmpty ? type.trim() : '${type.trim()}, ${details.trim()}';

class PedidoMaterialesWidget extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onOrdersChanged;
  final VoidCallback? onToggleMenu;
  final VoidCallback? onHoverMenu;
  final bool isPinned;

  const PedidoMaterialesWidget({
    super.key,
    this.embedded = false,
    this.onOrdersChanged,
    this.onToggleMenu,
    this.onHoverMenu,
    this.isPinned = false,
  });

  @override
  State<PedidoMaterialesWidget> createState() => PedidoMaterialesWidgetState();
}

class PedidoMaterialesWidgetState extends State<PedidoMaterialesWidget> {
  static const _storageKey = 'pedido_materiales_widget_v1';
  static const _consumablesResetKey = 'pedido_materiales_consumables_reset_v1';
  static const _otro = 'Otro (escribir)';
  static const _defaultMaterials = [
    'PLA',
    'PETG',
    'ABS',
    'ASA',
    'TPU (flexible)',
    'Nylon',
    'Resina',
  ];
  static const _defaultColors = [
    'Marrón Van Dyke',
    'Marrón',
    'Ocre amarillo',
    'Azul de Prusia',
    'Oro',
    'Silver',
    'Negro',
    'Blanco',
    'Gris',
    'Rojo',
    'Azul',
    'Verde',
    'Amarillo',
    'Naranja',
    'Transparente',
  ];

  final List<_OrderDraft> _orderDrafts = [_OrderDraft()];

  final List<String> _materials = List<String>.from(_defaultMaterials);
  final List<String> _colors = List<String>.from(_defaultColors);
  final List<String> _consumables = [];
  final List<_MaterialOrder> _orders = [];
  final ScrollController _ordersTableScrollController = ScrollController();

  bool _expanded = false;
  bool _consumablesOnly = false;
  bool _consumablesVisible = false;
  bool _loading = true;
  bool _saving = false;
  String? _storageError;
  final Set<String> _lastSubmittedBatchIds = {};

  String? _selectedBatchId;

  void prefillOrder({
    required String material,
    required String color,
    double? spoolGrams,
  }) {
    setState(() {
      _expanded = true;
      final draft = _orderDrafts.first;
      _mergeUnique(_materials, [material]);
      draft.selectedMaterial = material;
      _mergeUnique(_colors, [color]);
      draft.selectedColor = color;
      if (spoolGrams != null && spoolGrams > 0) {
        draft.spoolWeightController.text = '${spoolGrams.toInt()} g';
      }
      draft.selectedUrgency = 'Rojo';
      draft.urgencyDetailsController.text = _joinUrgencyDescription(
        'Reposición de inventario',
        'Carrete agotado o con stock bajo en laboratorio',
      );
    });
    _showMessage(
      'Se cargó $material ($color) en el formulario de pedido.',
    );
  }

  Widget buildOrdersList(BuildContext context) {
    if (_loading) return const LinearProgressIndicator(minHeight: 3);
    return StatefulBuilder(
      builder: (context, setListState) {
        return _buildOrdersTable(
          context,
          title: 'Lista de pedido',
          onStateUpdate: () {
            if (mounted) setState(() {});
            setListState(() {});
          },
        );
      },
    );
  }

  void _notifyOrdersChanged() {
    widget.onOrdersChanged?.call();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedData());
  }

  @override
  void dispose() {
    _ordersTableScrollController.dispose();
    for (final draft in _orderDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_storageKey);
      final shouldResetConsumables =
          !(preferences.getBool(_consumablesResetKey) ?? false);
      Map<String, dynamic>? decoded;
      if (saved != null) {
        final savedData = jsonDecode(saved);
        if (savedData is! Map<String, dynamic>) {
          throw const FormatException('El contenido guardado no es válido.');
        }
        decoded = savedData;
        if (shouldResetConsumables) {
          decoded['consumables'] = <String>[];
          final savedOrders = decoded['orders'];
          if (savedOrders is List) {
            decoded['orders'] = savedOrders.map((savedOrder) {
              if (savedOrder is! Map<String, dynamic>) {
                throw const FormatException(
                  'Los datos de un pedido no son válidos.',
                );
              }
              return <String, dynamic>{
                ...savedOrder,
                'consumables': <String>[],
                'consumableRequests': <Object?>[],
              }..remove('consumable');
            }).toList();
          }
        }

        final loadedMaterials = _readStringList(decoded['materials']);
        final loadedColors = _readStringList(decoded['colors']);
        final loadedConsumables = _readStringList(decoded['consumables']);
        final loadedOrders = _readOrders(decoded['orders']);

        if (!mounted) return;
        setState(() {
          _mergeUnique(_materials, loadedMaterials);
          _mergeUnique(_colors, loadedColors);
          _mergeUnique(_consumables, loadedConsumables);
          _orders
            ..clear()
            ..addAll(loadedOrders);
        });
      }
      if (shouldResetConsumables) {
        if (decoded != null) {
          final savedSuccessfully = await preferences.setString(
            _storageKey,
            jsonEncode(decoded),
          );
          if (!savedSuccessfully) {
            throw StateError(
                'No se pudieron borrar los consumibles guardados.');
          }
        }
        final resetMarked =
            await preferences.setBool(_consumablesResetKey, true);
        if (!resetMarked) {
          throw StateError('No se pudo registrar el borrado de consumibles.');
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Error al cargar los pedidos de materiales: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(
        'No se pudieron cargar los pedidos guardados. $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _notifyOrdersChanged();
      }
    }
  }

  Future<void> _saveData() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _storageKey,
        jsonEncode({
          'materials': _materials,
          'colors': _colors,
          'consumables': _consumables,
          'orders': _orders.map((order) => order.toJson()).toList(),
        }),
      );
      if (!saved) {
        throw StateError('El almacenamiento rechazó los cambios.');
      }
      _storageError = null;
    } catch (error, stackTrace) {
      debugPrint('Error al guardar los pedidos de materiales: $error');
      debugPrintStack(stackTrace: stackTrace);
      _storageError =
          'No se pudieron guardar los cambios. Permanecerán solo mientras la app esté abierta.';
      _showMessage('Error al guardar los pedidos: $error', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _readStringList(Object? value) {
    if (value == null) return [];
    if (value is! List) {
      throw const FormatException('Una de las listas guardadas no es válida.');
    }
    return value.map((item) {
      if (item is! String) {
        throw const FormatException('Se encontró un elemento no válido.');
      }
      return item;
    }).toList();
  }

  List<_MaterialOrder> _readOrders(Object? value) {
    if (value == null) return [];
    if (value is! List) {
      throw const FormatException('La lista de pedidos guardada no es válida.');
    }
    return value.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Se encontró un pedido no válido.');
      }
      return _MaterialOrder.fromJson(item);
    }).toList();
  }

  void _mergeUnique(List<String> target, Iterable<String> values) {
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isNotEmpty &&
          !target.any(
            (existing) => existing.toLowerCase() == normalized.toLowerCase(),
          )) {
        target.add(normalized);
      }
    }
  }

  String? _resolveManualValue({
    required String? selection,
    required TextEditingController controller,
    required String fieldName,
  }) {
    if (selection == _otro) {
      final value = controller.text.trim();
      if (value.isEmpty) {
        _showMessage('Escribe el nombre de $fieldName.', isError: true);
        return null;
      }
      return value;
    }
    return selection;
  }

  String? _normalizedPageLink(String value) {
    final entered = value.trim();
    if (entered.isEmpty) return null;
    final candidate = entered.contains('://') ? entered : 'https://$entered';
    final uri = Uri.tryParse(candidate);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return uri.toString();
  }

  Future<void> _addOrder() async {
    final sharedDraft = _orderDrafts.first;
    final consumables = <String>[];
    final consumableRequests = <_ConsumableRequest>[];
    final newConsumables = <String>[];
    for (var index = 0; index < sharedDraft.consumableForms.length; index++) {
      final form = sharedDraft.consumableForms[index];
      if (form.selected == null) continue;
      if (form.selectedUrgency == null) {
        _showMessage(
          'Selecciona el nivel de urgencia del consumible ${index + 1}.',
          isError: true,
        );
        return;
      }
      final urgencyDescription = form.urgencyDetailsController.text.trim();
      if (urgencyDescription.isEmpty) {
        _showMessage(
          'Escribe el detalle de urgencia del consumible ${index + 1}.',
          isError: true,
        );
        return;
      }
      final urgency = _parseUrgencyDescription(urgencyDescription);
      if (form.selected == null) continue;

      final enteredLink = form.linkController.text.trim();
      final consumableLink =
          enteredLink.isEmpty ? null : _normalizedPageLink(enteredLink);
      if (enteredLink.isNotEmpty && consumableLink == null) {
        _showMessage(
          'Escribe un enlace válido para el consumible ${index + 1}.',
          isError: true,
        );
        return;
      }
      final consumable = _resolveManualValue(
        selection: form.selected,
        controller: form.manualController,
        fieldName: 'consumible',
      );
      if (consumable == null) return;
      final consumableCostText =
          form.costController.text.trim().replaceAll(',', '.');
      final consumableCost = consumableCostText.isEmpty
          ? 0.0
          : double.tryParse(consumableCostText);
      if (consumableCost == null || consumableCost < 0) {
        _showMessage(
          'Escribe un costo válido para el consumible ${index + 1}.',
          isError: true,
        );
        return;
      }
      consumables.add(consumable);
      if (form.selected == _otro) newConsumables.add(consumable);
      consumableRequests.add(
        _ConsumableRequest(
          name: consumable,
          quantity: form.quantityController.text.trim(),
          link: consumableLink,
          urgency: form.selectedUrgency!,
          urgencyType: urgency.type,
          urgencyDetails: urgency.details,
          cost: consumableCost,
        ),
      );
    }

    final orders = <_MaterialOrder>[];
    final newMaterials = <String>[];
    final newColors = <String>[];
    final createdAt = DateTime.now();
    final now = createdAt.microsecondsSinceEpoch;
    final batchId = 'batch_$now';
    if (_consumablesOnly) {
      if (consumableRequests.isEmpty) {
        _showMessage(
          'Agrega al menos un consumible para crear este pedido.',
          isError: true,
        );
        return;
      }
      for (var index = 0; index < consumableRequests.length; index++) {
        final request = consumableRequests[index];
        orders.add(
          _MaterialOrder(
            id: '${now}_consumable_$index',
            batchId: batchId,
            createdAt: createdAt,
            link: request.link ?? '',
            material: '',
            color: '',
            urgency: request.urgency,
            urgencyType: request.urgencyType,
            urgencyDetails: request.urgencyDetails,
            consumables: [request.name],
            consumableRequests: [request],
            spoolGrams: null,
            usedGrams: null,
            cost: 0,
            isConsumableOnly: true,
          ),
        );
      }
    } else {
      for (var index = 0; index < _orderDrafts.length; index++) {
        final draft = _orderDrafts[index];
        if (draft.selectedUrgency == null) {
          _showMessage(
            'Selecciona el nivel de urgencia del pedido ${index + 1}.',
            isError: true,
          );
          return;
        }
        final urgencyDescription = draft.urgencyDetailsController.text.trim();
        if (urgencyDescription.isEmpty) {
          _showMessage(
            'Escribe el detalle de urgencia del pedido ${index + 1}.',
            isError: true,
          );
          return;
        }
        final urgency = _parseUrgencyDescription(urgencyDescription);
        final costText = draft.costController.text.trim().replaceAll(',', '.');
        final cost = costText.isEmpty ? 0.0 : double.tryParse(costText);
        if (cost == null || cost < 0) {
          _showMessage(
            'Escribe un costo válido para el pedido ${index + 1}.',
            isError: true,
          );
          return;
        }

        final link = _normalizedPageLink(draft.linkController.text);
        if (link == null) {
          _showMessage(
            'Escribe un enlace válido para el pedido ${index + 1}.',
            isError: true,
          );
          return;
        }

        final material = _resolveManualValue(
          selection: draft.selectedMaterial,
          controller: draft.manualMaterialController,
          fieldName: 'material',
        );
        if (material == null) {
          if (draft.selectedMaterial != _otro) {
            _showMessage(
              'Selecciona el material del pedido ${index + 1}.',
              isError: true,
            );
          }
          return;
        }

        final color = _resolveManualValue(
          selection: draft.selectedColor,
          controller: draft.manualColorController,
          fieldName: 'color',
        );
        if (color == null) {
          if (draft.selectedColor != _otro) {
            _showMessage(
              'Selecciona el color del pedido ${index + 1}.',
              isError: true,
            );
          }
          return;
        }

        final spoolText = draft.spoolWeightController.text.trim();
        final spoolGrams = parseWeightToGrams(spoolText);
        if (spoolText.isNotEmpty && spoolGrams == null) {
          _showMessage(
            'No entendí el peso del carrete del pedido ${index + 1}.',
            isError: true,
          );
          return;
        }

        if (draft.selectedMaterial == _otro) newMaterials.add(material);
        if (draft.selectedColor == _otro) newColors.add(color);
        orders.add(
          _MaterialOrder(
            id: '${now}_$index',
            batchId: batchId,
            createdAt: createdAt,
            link: link,
            material: material,
            color: color,
            urgency: draft.selectedUrgency!,
            urgencyType: urgency.type,
            urgencyDetails: urgency.details,
            consumables: consumables,
            consumableRequests: consumableRequests,
            spoolGrams: spoolGrams,
            usedGrams: null,
            cost: cost,
          ),
        );
      }
    }

    setState(() {
      _mergeUnique(_materials, newMaterials);
      _mergeUnique(_colors, newColors);
      _mergeUnique(_consumables, newConsumables);
      _orders.insertAll(0, orders);
      _lastSubmittedBatchIds
        ..clear()
        ..addAll(orders.map((o) => o.id));
      for (final draft in _orderDrafts) {
        draft.dispose();
      }
      _orderDrafts
        ..clear()
        ..add(_OrderDraft());
    });
    await _saveData();
    _notifyOrdersChanged();
  }

  void _removeOrderDraft(_OrderDraft draft) {
    if (_orderDrafts.indexOf(draft) <= 0) return;
    setState(() => _orderDrafts.remove(draft));
    draft.dispose();
  }

  Future<void> _removeOrder(_MaterialOrder order) async {
    setState(() => _orders.removeWhere((item) => item.id == order.id));
    await _saveData();
    _notifyOrdersChanged();
  }

  Future<void> _removeConsumable(
    _MaterialOrder order,
    int consumableIndex,
  ) async {
    final orderIndex = _orders.indexWhere((item) => item.id == order.id);
    if (orderIndex < 0 ||
        consumableIndex < 0 ||
        consumableIndex >= order.consumableRequests.length) {
      return;
    }

    final updatedRequests = List<_ConsumableRequest>.from(
      order.consumableRequests,
    )..removeAt(consumableIndex);
    setState(() {
      if (updatedRequests.isEmpty && order.isConsumableOnly) {
        _orders.removeAt(orderIndex);
        return;
      }
      _orders[orderIndex] = _MaterialOrder(
        id: order.id,
        batchId: order.batchId,
        createdAt: order.createdAt,
        link: order.isConsumableOnly
            ? updatedRequests.first.link ?? ''
            : order.link,
        material: order.material,
        color: order.color,
        urgency: order.isConsumableOnly
            ? updatedRequests.first.urgency
            : order.urgency,
        urgencyType: order.isConsumableOnly
            ? updatedRequests.first.urgencyType
            : order.urgencyType,
        urgencyDetails: order.isConsumableOnly
            ? updatedRequests.first.urgencyDetails
            : order.urgencyDetails,
        consumables: updatedRequests.map((request) => request.name).toList(),
        consumableRequests: updatedRequests,
        spoolGrams: order.spoolGrams,
        usedGrams: order.usedGrams,
        cost: order.cost,
        isConsumableOnly: order.isConsumableOnly,
      );
    });
    await _saveData();
    _notifyOrdersChanged();
  }

  Future<void> _editConsumable(
    _MaterialOrder order,
    int consumableIndex,
  ) async {
    if (consumableIndex < 0 ||
        consumableIndex >= order.consumableRequests.length) {
      return;
    }
    final draft = _ConsumableEditDraft.fromRequest(
      order.consumableRequests[consumableIndex],
    );
    String? validationError;
    final updatedRequest = await showDialog<_ConsumableRequest>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colors = theme.colorScheme;

        Widget input(
          String label,
          TextEditingController controller, {
          String? hint,
          TextInputType? keyboardType,
          Key? key,
        }) =>
            _textInput(
              dialogContext,
              key: key,
              controller: controller,
              label: label,
              hint: hint ?? '',
              keyboardType: keyboardType,
            );

        return _ConsumableEditDraftDisposer(
          draft: draft,
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) => AlertDialog(
              title: const Text('Editar consumible'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      input(
                        'Nombre del consumible',
                        draft.nameController,
                        hint: 'Boquilla, pegamento...',
                        key: const ValueKey('edit_single_consumable_name'),
                      ),
                      const SizedBox(height: 12),
                      input(
                        'Cantidad',
                        draft.quantityController,
                        hint: 'Ej. 5 litros o 10 piezas',
                        key: const ValueKey('edit_single_consumable_quantity'),
                      ),
                      const SizedBox(height: 12),
                      input(
                        'Link de donde se encontró el consumible',
                        draft.linkController,
                        hint: 'https://...',
                        keyboardType: TextInputType.url,
                        key: const ValueKey('edit_single_consumable_link'),
                      ),
                      const SizedBox(height: 16),
                      _urgencyDropdown(
                        dialogContext,
                        key: const ValueKey('edit_single_consumable_urgency'),
                        selectedUrgency: draft.urgency,
                        onChanged: (value) =>
                            setDialogState(() => draft.urgency = value),
                      ),
                      const SizedBox(height: 12),
                      input(
                        'Detalle y Texto de Urgencia',
                        draft.urgencyDetailsController,
                        hint: 'Ej. Reposición urgente, falta para entrega',
                        key: const ValueKey(
                          'edit_single_consumable_urgency_details',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 140,
                          child: input(
                            'Costo (\$)',
                            draft.costController,
                            hint: '0',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            key: const ValueKey('edit_single_consumable_cost'),
                          ),
                        ),
                      ),
                      if (validationError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          validationError!,
                          key: const ValueKey('edit_single_consumable_error'),
                          style: TextStyle(color: colors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  key: const ValueKey('save_single_consumable_edit'),
                  onPressed: () {
                    final name = draft.nameController.text.trim();
                    if (name.isEmpty) {
                      setDialogState(() => validationError =
                          'Escribe el nombre del consumible.');
                      return;
                    }
                    final enteredLink = draft.linkController.text.trim();
                    final link = enteredLink.isEmpty
                        ? null
                        : _normalizedPageLink(enteredLink);
                    if (enteredLink.isNotEmpty && link == null) {
                      setDialogState(() => validationError =
                          'Escribe un enlace válido para el consumible.');
                      return;
                    }
                    final costText =
                        draft.costController.text.trim().replaceAll(',', '.');
                    final cost =
                        costText.isEmpty ? 0.0 : double.tryParse(costText);
                    if (cost == null || cost < 0) {
                      setDialogState(
                          () => validationError = 'Escribe un costo válido.');
                      return;
                    }
                    final urgencyDescription =
                        draft.urgencyDetailsController.text.trim();
                    if (draft.urgency == null || urgencyDescription.isEmpty) {
                      setDialogState(() => validationError =
                          'Completa la urgencia del consumible.');
                      return;
                    }
                    final urgency =
                        _parseUrgencyDescription(urgencyDescription);
                    Navigator.of(dialogContext).pop(
                      _ConsumableRequest(
                        name: name,
                        quantity: draft.quantityController.text.trim(),
                        link: link,
                        urgency: draft.urgency!,
                        urgencyType: urgency.type,
                        urgencyDetails: urgency.details,
                        cost: cost,
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (updatedRequest == null || !mounted) return;
    final orderIndex = _orders.indexWhere((item) => item.id == order.id);
    if (orderIndex < 0 ||
        consumableIndex >= _orders[orderIndex].consumableRequests.length) {
      return;
    }
    final currentOrder = _orders[orderIndex];
    final updatedRequests = List<_ConsumableRequest>.from(
      currentOrder.consumableRequests,
    )..[consumableIndex] = updatedRequest;
    setState(() {
      _orders[orderIndex] = _MaterialOrder(
        id: currentOrder.id,
        batchId: currentOrder.batchId,
        createdAt: currentOrder.createdAt,
        link: currentOrder.isConsumableOnly
            ? updatedRequest.link ?? ''
            : currentOrder.link,
        material: currentOrder.material,
        color: currentOrder.color,
        urgency: currentOrder.isConsumableOnly
            ? updatedRequest.urgency
            : currentOrder.urgency,
        urgencyType: currentOrder.isConsumableOnly
            ? updatedRequest.urgencyType
            : currentOrder.urgencyType,
        urgencyDetails: currentOrder.isConsumableOnly
            ? updatedRequest.urgencyDetails
            : currentOrder.urgencyDetails,
        consumables: updatedRequests.map((request) => request.name).toList(),
        consumableRequests: updatedRequests,
        spoolGrams: currentOrder.spoolGrams,
        usedGrams: currentOrder.usedGrams,
        cost: currentOrder.cost,
        isConsumableOnly: currentOrder.isConsumableOnly,
      );
      _mergeUnique(_consumables, [updatedRequest.name]);
    });
    await _saveData();
    _notifyOrdersChanged();
  }

  Future<void> _editOrder(_MaterialOrder order) async {
    final filamentDrafts = <_OrderEditDraft>[_OrderEditDraft(order)];
    try {
      final updatedOrders = await showDialog<List<_MaterialOrder>>(
        context: context,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          final colors = theme.colorScheme;
          String? validationError;
          final draft = filamentDrafts.first;

          Widget input(
            String label,
            TextEditingController controller, {
            String? hint,
            TextInputType? keyboardType,
            Key? key,
            Widget? prefixIcon,
            Widget? suffix,
          }) {
            final isDark = theme.brightness == Brightness.dark;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  key: key,
                  controller: controller,
                  keyboardType: keyboardType,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _macInputDecoration(
                    dialogContext,
                    hintText: hint,
                    suffixIcon: suffix,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  ).copyWith(
                    prefixIcon: prefixIcon,
                  ),
                ),
              ],
            );
          }

          Widget urgencySelector({
            required Key key,
            required String? selectedUrgency,
            required ValueChanged<String?> onChanged,
          }) {
            final isDark = theme.brightness == Brightness.dark;
            const options = ['Rojo', 'Amarillo', 'Verde'];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nivel de Urgencia',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  key: key,
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141820) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: options.map((opt) {
                      final isSelected = selectedUrgency == opt;
                      final optColor = _urgencyColor(dialogContext, opt);
                      final labelText = opt == 'Rojo'
                          ? 'Alta'
                          : opt == 'Amarillo'
                              ? 'Media'
                              : 'Baja';

                      return Expanded(
                        child: InkWell(
                          onTap: () => onChanged(opt),
                          borderRadius: BorderRadius.circular(7),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(vertical: 6.5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? optColor.withValues(alpha: 0.18) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                              border: isSelected
                                  ? Border.all(
                                      color: optColor.withValues(alpha: isDark ? 0.45 : 0.40),
                                      width: 1,
                                    )
                                  : null,
                              boxShadow: isSelected && !isDark
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: optColor,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: optColor.withValues(alpha: 0.45),
                                              blurRadius: 4,
                                              spreadRadius: 0.5,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$opt ($labelText)',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          }

          Widget sectionHeader(String title, IconData icon, {Widget? trailing}) {
            final isDark = theme.brightness == Brightness.dark;
            return Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: isDark ? 0.16 : 0.09),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 13, color: colors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    fontSize: 13.5,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing,
                ],
              ],
            );
          }

          final isDark = theme.brightness == Brightness.dark;

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(22, 18, 16, 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 22),
              actionsPadding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit_note_rounded, size: 18, color: colors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Editar pedido',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: 'Cerrar',
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 720,
                height: MediaQuery.of(dialogContext).size.height * 0.76,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header card: Enlace de compra
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161A22) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: input(
                          'Enlace de la tienda / publicación',
                          filamentDrafts.first.linkController,
                          hint: 'https://ejemplo.com/producto',
                          keyboardType: TextInputType.url,
                          key: const ValueKey('edit_order_link'),
                          prefixIcon: Icon(
                            Icons.link_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // SECCIÓN FILAMENTOS
                      sectionHeader(
                        'Material y Filamentos',
                        Icons.layers_outlined,
                        trailing: TextButton.icon(
                          key: const ValueKey('edit_add_filament'),
                          onPressed: () => setDialogState(
                            () => filamentDrafts.add(_OrderEditDraft.empty()),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: const Text('Agregar filamento', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      ...filamentDrafts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final filament = entry.value;
                        Key fieldKey(String name) => ValueKey(
                              index == 0 ? name : '${name}_$index',
                            );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161A22) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (filamentDrafts.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Filamento ${index + 1}',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: colors.primary,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (index > 0)
                                        IconButton(
                                          key: ValueKey('edit_remove_filament_$index'),
                                          tooltip: 'Quitar filamento',
                                          onPressed: () => setDialogState(() {
                                            filamentDrafts.removeAt(index).dispose();
                                          }),
                                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                          color: colors.error,
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                                        ),
                                    ],
                                  ),
                                ),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final colWidth = (constraints.maxWidth - 20) / 3;
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: colWidth,
                                        child: input(
                                          'Material',
                                          filament.materialController,
                                          hint: 'Ej. PLA+, PETG',
                                          key: fieldKey('edit_order_material'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: colWidth,
                                        child: input(
                                          'Color',
                                          filament.colorController,
                                          hint: 'Ej. Negro, Azul',
                                          key: fieldKey('edit_order_color'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: colWidth,
                                        child: input(
                                          'Peso carrete',
                                          filament.weightController,
                                          hint: 'Ej. 1000 g',
                                          key: fieldKey('edit_order_weight'),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              urgencySelector(
                                key: fieldKey('edit_order_urgency'),
                                selectedUrgency: filament.urgency,
                                onChanged: (value) => setDialogState(() {
                                  filament.urgency = value;
                                }),
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  const costWidth = 130.0;
                                  final detailWidth = constraints.maxWidth - costWidth - 10;
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: detailWidth,
                                        child: input(
                                          'Motivo / Justificación de Urgencia',
                                          filament.urgencyDetailsController,
                                          hint: 'Ej. Material agotado para prácticas',
                                          key: fieldKey('edit_order_urgency_details'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: costWidth,
                                        child: input(
                                          'Precio (\$)',
                                          filament.costController,
                                          hint: '0.00',
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          key: fieldKey('edit_order_cost'),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 12),

                      // SECCIÓN CONSUMIBLES
                      sectionHeader(
                        'Consumibles y Refacciones',
                        Icons.build_circle_outlined,
                        trailing: TextButton.icon(
                          key: const ValueKey('edit_add_consumable'),
                          onPressed: () => setDialogState(
                            () => draft.consumableDrafts.add(_ConsumableEditDraft()),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: const Text('Agregar consumible', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (draft.consumableDrafts.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161A22).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Sin consumibles adicionales en este pedido.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        )
                      else
                        ...draft.consumableDrafts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final consumable = entry.value;
                          return Container(
                            key: ValueKey('edit_consumable_row_$index'),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF161A22) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Consumible ${index + 1}',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colors.primary,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      key: ValueKey('edit_remove_consumable_$index'),
                                      tooltip: 'Quitar consumible',
                                      onPressed: () => setDialogState(() {
                                        draft.consumableDrafts.removeAt(index).dispose();
                                      }),
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                      color: colors.error,
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    const qtyWidth = 130.0;
                                    final nameWidth = constraints.maxWidth - qtyWidth - 10;
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: nameWidth,
                                          child: input(
                                            'Nombre del consumible',
                                            consumable.nameController,
                                            hint: 'Ej. Boquilla 0.4 mm, alcohol...',
                                            key: ValueKey('edit_consumable_name_$index'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: qtyWidth,
                                          child: input(
                                            'Cantidad',
                                            consumable.quantityController,
                                            hint: 'Ej. 2 pzas',
                                            key: ValueKey('edit_consumable_quantity_$index'),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                input(
                                  'Enlace del consumible (opcional)',
                                  consumable.linkController,
                                  hint: 'https://...',
                                  keyboardType: TextInputType.url,
                                  key: ValueKey('edit_consumable_link_$index'),
                                  prefixIcon: Icon(
                                    Icons.link_rounded,
                                    size: 15,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                urgencySelector(
                                  key: ValueKey('edit_consumable_urgency_$index'),
                                  selectedUrgency: consumable.urgency,
                                  onChanged: (value) => setDialogState(() {
                                    consumable.urgency = value;
                                  }),
                                ),
                                const SizedBox(height: 10),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    const costWidth = 130.0;
                                    final detailWidth = constraints.maxWidth - costWidth - 10;
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: detailWidth,
                                          child: input(
                                            'Motivo / Justificación de Urgencia',
                                            consumable.urgencyDetailsController,
                                            hint: 'Ej. Mantenimiento preventivo',
                                            key: ValueKey('edit_consumable_details_$index'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: costWidth,
                                          child: input(
                                            'Precio (\$)',
                                            consumable.costController,
                                            hint: '0.00',
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            key: ValueKey('edit_consumable_cost_$index'),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }),

                      if (validationError != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.error.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: colors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  validationError!,
                                  key: const ValueKey('edit_order_error'),
                                  style: TextStyle(color: colors.error, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  key: const ValueKey('save_order_edits'),
                  onPressed: () {
                    final link = _normalizedPageLink(
                      draft.linkController.text,
                    );
                    if (link == null) {
                      setDialogState(() => validationError =
                          'Escribe un enlace válido (por ejemplo, https://tienda.com).');
                      return;
                    }

                    final requests = <_ConsumableRequest>[];
                    for (var index = 0;
                        index < draft.consumableDrafts.length;
                        index++) {
                      final consumable = draft.consumableDrafts[index];
                      final name = consumable.nameController.text.trim();
                      if (name.isEmpty) {
                        setDialogState(() => validationError =
                            'Escribe el nombre del consumible ${index + 1} o quítalo.');
                        return;
                      }
                      final consumableUrgency = consumable.urgency;
                      final enteredLink = consumable.linkController.text.trim();
                      final consumableLink = enteredLink.isEmpty
                          ? null
                          : _normalizedPageLink(enteredLink);
                      if (enteredLink.isNotEmpty && consumableLink == null) {
                        setDialogState(() => validationError =
                            'Escribe un enlace válido para el consumible ${index + 1}.');
                        return;
                      }
                      final consumableCostText = consumable.costController.text
                          .trim()
                          .replaceAll(',', '.');
                      final consumableCost = consumableCostText.isEmpty
                          ? 0.0
                          : double.tryParse(consumableCostText);
                      if (consumableCost == null || consumableCost < 0) {
                        setDialogState(() => validationError =
                            'Escribe un costo válido para el consumible ${index + 1}.');
                        return;
                      }
                      final urgencyDescription =
                          consumable.urgencyDetailsController.text.trim();
                      if (consumableUrgency == null ||
                          urgencyDescription.isEmpty) {
                        setDialogState(() => validationError =
                            'Completa la urgencia del consumible ${index + 1}.');
                        return;
                      }
                      final urgency =
                          _parseUrgencyDescription(urgencyDescription);
                      requests.add(
                        _ConsumableRequest(
                          name: name,
                          quantity: consumable.quantityController.text.trim(),
                          link: consumableLink,
                          urgency: consumableUrgency,
                          urgencyType: urgency.type,
                          urgencyDetails: urgency.details,
                          cost: consumableCost,
                        ),
                      );
                    }

                    final updatedFilaments = <_MaterialOrder>[];
                    final createdAt = DateTime.now();
                    for (var index = 0;
                        index < filamentDrafts.length;
                        index++) {
                      final filament = filamentDrafts[index];
                      final material = filament.materialController.text.trim();
                      final color = filament.colorController.text.trim();
                      final weightText = filament.weightController.text.trim();
                      final spoolGrams = weightText.isEmpty
                          ? null
                          : parseWeightToGrams(weightText);
                      final costText = filament.costController.text
                          .trim()
                          .replaceAll(',', '.');
                      final cost =
                          costText.isEmpty ? 0.0 : double.tryParse(costText);
                      final urgency = filament.urgency;
                      final urgencyDescription =
                          filament.urgencyDetailsController.text.trim();

                      if (material.isEmpty || color.isEmpty) {
                        setDialogState(() => validationError =
                            'El material y el color del filamento ${index + 1} son obligatorios.');
                        return;
                      }
                      if (urgency == null) {
                        setDialogState(() => validationError =
                            'Selecciona el nivel de urgencia del filamento ${index + 1}.');
                        return;
                      }
                      if (urgencyDescription.isEmpty) {
                        setDialogState(() => validationError =
                            'Completa el detalle de urgencia del filamento ${index + 1}.');
                        return;
                      }
                      final urgencyParts =
                          _parseUrgencyDescription(urgencyDescription);
                      if (weightText.isNotEmpty && spoolGrams == null) {
                        setDialogState(() => validationError =
                            'Escribe un peso válido para el filamento ${index + 1}, por ejemplo 1 kg o 500 g.');
                        return;
                      }
                      if (cost == null || cost < 0) {
                        setDialogState(() => validationError =
                            'Escribe un costo válido para el filamento ${index + 1}.');
                        return;
                      }

                      final original = filament.originalOrder;
                      updatedFilaments.add(
                        _MaterialOrder(
                          id: original?.id ??
                              '${createdAt.microsecondsSinceEpoch}_edit_$index',
                          batchId: original?.batchId ?? order.batchId,
                          createdAt: original?.createdAt ?? createdAt,
                          link: link,
                          material: material,
                          color: color,
                          urgency: urgency,
                          urgencyType: urgencyParts.type,
                          urgencyDetails: urgencyParts.details,
                          consumables:
                              requests.map((request) => request.name).toList(),
                          consumableRequests: requests,
                          spoolGrams: spoolGrams,
                          usedGrams: original?.usedGrams,
                          cost: cost,
                        ),
                      );
                    }

                    Navigator.of(dialogContext).pop(updatedFilaments);
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar cambios'),
                ),
              ],
            ),
          );
        },
      );

      if (updatedOrders == null || !mounted) return;
      setState(() {
        final orderIndex = _orders.indexWhere((item) => item.id == order.id);
        if (orderIndex < 0) return;
        _orders.replaceRange(orderIndex, orderIndex + 1, updatedOrders);
        _mergeUnique(
          _materials,
          updatedOrders.map((updatedOrder) => updatedOrder.material),
        );
        _mergeUnique(
          _colors,
          updatedOrders.map((updatedOrder) => updatedOrder.color),
        );
        _mergeUnique(
          _consumables,
          updatedOrders.expand((updatedOrder) => updatedOrder.consumables),
        );
      });
      await _saveData();
      _notifyOrdersChanged();
    } finally {
      for (final filament in filamentDrafts) {
        filament.dispose();
      }
    }
  }

  Future<void> _addCustomColorToPalette(_OrderDraft draft) async {
    final color = draft.manualColorController.text.trim();
    if (color.isEmpty) {
      _showMessage('Escribe el nombre o el código del color.', isError: true);
      return;
    }

    setState(() {
      _mergeUnique(_colors, [color]);
      draft.selectedColor = _colors.firstWhere(
        (existing) => existing.toLowerCase() == color.toLowerCase(),
      );
      draft.manualColorController.clear();
    });
    await _saveData();
  }

  Future<void> _selectFilamentColor(_OrderDraft draft, String? value) async {
    if (value == null) return;
    final colorDraft = draft.manualColorController.text.trim();
    final isNewDraft = colorDraft.isNotEmpty &&
        value.toLowerCase() == colorDraft.toLowerCase() &&
        !_colors
            .any((color) => color.toLowerCase() == colorDraft.toLowerCase());
    setState(() {
      if (isNewDraft) _mergeUnique(_colors, [value]);
      draft.selectedColor = value;
      draft.manualColorController.clear();
    });
    if (isNewDraft) await _saveData();
  }

  Future<void> _openPageLink(String value) async {
    final link = _normalizedPageLink(value);
    if (link == null) {
      _showMessage(
        'Escribe un enlace válido (por ejemplo, https://tienda.com).',
        isError: true,
      );
      return;
    }
    try {
      final uri = Uri.parse(link);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw StateError('El navegador no pudo abrir $link.');
      }
    } catch (error, stackTrace) {
      debugPrint('Error al abrir el enlace del material: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage('No se pudo abrir el enlace: $error', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final pagePadding = constraints.maxWidth < 600 ? 14.0 : 24.0;
        final pageWidth = constraints.maxWidth;
        if (widget.embedded) {
          return _buildEmbeddedContent(context, pageWidth);
        }
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: darkAppBar(
            'Pedido de Material',
            widget.onToggleMenu ?? () {},
            subtitle: 'Gestión de solicitudes de filamento y consumibles',
            leadingWidget: const SidebarToggleIcon(),
            onHoverEnter: widget.onHoverMenu,
            hideLeading: widget.isPinned,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme, isDark),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => _expanded = !_expanded),
                        icon: Icon(
                          _expanded ? Icons.close_rounded : Icons.add_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _expanded ? 'Ocultar pedidos' : 'Nuevo pedido',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 16),
                  if (_loading)
                    const LinearProgressIndicator(minHeight: 3)
                  else ...[
                    _buildForm(context, pageWidth),
                    const SizedBox(height: 20),
                    if (!widget.embedded) _buildOrdersTable(context),
                  ],
                ],
                if (_storageError != null) ...[
                  const SizedBox(height: 12),
                  _buildStorageWarning(context),
                ],
                if (_saving) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 2),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmbeddedContent(
    BuildContext context,
    double maxWidth,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_expanded)
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _expanded = true),
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'Nuevo pedido',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    elevation: 1,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                    ? 0.20
                                    : 0.10,
                          ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.post_add_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Nuevo pedido',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => setState(() => _expanded = false),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 15,
                    ),
                    label: const Text(
                      'Cerrar formulario de pedido',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF0F2F5),
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        if (_expanded) ...[
          const SizedBox(height: 14),
          _buildForm(context, maxWidth),
          const SizedBox(height: 14),
          if (!widget.embedded) _buildOrdersTable(context),
        ],
        if (_storageError != null) ...[
          const SizedBox(height: 10),
          _buildStorageWarning(context),
        ],
        if (_saving) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.secondary, 0.65)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: isDark ? 0.22 : 0.16),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_cart_checkout_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido de materiales',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Organiza las compras y prioridades del laboratorio',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, double maxWidth) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      key: const ValueKey('order_draft_template'),
      padding: EdgeInsets.all(maxWidth < 600 ? 16 : 24),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(
                    alpha: isDark ? 0.22 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requisición de Materiales e Insumos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rellena los datos de los filamentos o repuestos y agrégalos a la tabla de pedidos.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '¿Qué deseas pedir?',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<bool>(
              key: const ValueKey('order_type_selector'),
              segments: [
                ButtonSegment(
                  value: false,
                  icon: _consumablesOnly
                      ? const _FilamentSpoolIcon(
                          key: ValueKey('filament_spool_selector_icon'),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text('Filamento'),
                ),
                ButtonSegment(
                  value: true,
                  icon: _consumablesOnly
                      ? const Icon(Icons.check_rounded)
                      : const Icon(Icons.build_outlined),
                  label: const Text('Solo consumibles'),
                ),
              ],
              selected: {_consumablesOnly},
              onSelectionChanged: (selection) {
                setState(() => _consumablesOnly = selection.first);
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_consumablesOnly)
            _buildOrderDraftForm(
              context,
              maxWidth,
              _orderDrafts.first,
              _orderDrafts.length - 1,
            )
          else
            for (var index = 0; index < _orderDrafts.length; index++) ...[
              if (index > 0) const SizedBox(height: 16),
              _buildOrderDraftForm(
                context,
                maxWidth,
                _orderDrafts[index],
                index,
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildOrderDraftForm(
    BuildContext context,
    double maxWidth,
    _OrderDraft draft,
    int draftIndex,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sharedDraft = _orderDrafts.first;
    final pageInset =
        widget.embedded ? 0.0 : (maxWidth < 600 ? 14.0 : 24.0) * 2;
    final cardInset = (maxWidth < 600 ? 16.0 : 22.0) * 2;
    final availableWidth = maxWidth - pageInset - cardInset;
    final columns = availableWidth >= 1000
        ? 3
        : availableWidth >= 620
            ? 2
            : 1;
    final fieldWidth = (availableWidth - (12 * (columns - 1))) / columns;
    final orderUrgencyDropdownWidth =
        availableWidth >= 620 ? 400.0 : availableWidth;
    final consumableSelectorWidth =
        availableWidth >= 620 ? (availableWidth - 12) / 2 : availableWidth;
    Widget field(Widget child, {double? width}) =>
        SizedBox(width: width ?? fieldWidth, child: child);
    Widget addConsumablesButton() => SizedBox(
          width: 220,
          height: 40,
          child: FilledButton.tonalIcon(
            key: const ValueKey('show_consumables_button'),
            onPressed: () {
              setState(() {
                if (_consumablesVisible || _consumablesOnly) {
                  sharedDraft.consumableForms.add(_ConsumableForm());
                } else {
                  _consumablesVisible = true;
                }
              });
            },
            icon: const Icon(Icons.add_circle_outline, size: 17),
            label: Text(
              _consumablesVisible || _consumablesOnly
                  ? 'Agregar otro consumible'
                  : 'Agregar consumibles',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFF0F2F5),
              foregroundColor: theme.colorScheme.onSurface,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_consumablesOnly)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1E26) : const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : const Color(0xFFE9EBEF),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _formSectionTitle(
                        context,
                        'Datos Combinados del Material',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: isDark ? 0.16 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Pedido ${draftIndex + 1}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (draftIndex > 0)
                      IconButton(
                        key: ValueKey('remove_order_draft_$draftIndex'),
                        tooltip: 'Quitar pedido',
                        onPressed: () => _removeOrderDraft(draft),
                        icon: const Icon(Icons.remove_circle_outline_rounded,
                            size: 18),
                        color: theme.colorScheme.error,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _textInput(
                  context,
                  key: ValueKey('order_link_${draft.id}'),
                  controller: draft.linkController,
                  label: 'Link de la página donde se encontró el material',
                  hint: 'https://...',
                  keyboardType: TextInputType.url,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Pegar enlace',
                        onPressed: () async {
                          final data =
                              await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null &&
                              data!.text!.trim().isNotEmpty) {
                            draft.linkController.text = data.text!.trim();
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.content_paste_rounded, size: 20),
                      ),
                      IconButton(
                        tooltip: 'Abrir página web',
                        onPressed: () =>
                            _openPageLink(draft.linkController.text),
                        icon:
                            const Icon(Icons.open_in_browser_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
                _formSectionTitle(context, 'Material y color',
                    icon: Icons.palette_outlined),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final materialColumns = constraints.maxWidth >= 660
                        ? 3
                        : constraints.maxWidth >= 620
                            ? 2
                            : 1;
                    final materialFieldWidth =
                        (constraints.maxWidth - 12 * (materialColumns - 1)) /
                            materialColumns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: materialFieldWidth,
                          child: _dropdown(
                            context,
                            key: ValueKey('order_material_$draftIndex'),
                            label: 'Material',
                            value: draft.selectedMaterial,
                            options: [..._materials, _otro],
                            hint: 'Elegir material',
                            onChanged: (value) =>
                                setState(() => draft.selectedMaterial = value),
                          ),
                        ),
                        SizedBox(
                          width: materialFieldWidth,
                          child: _filamentColorDropdown(context, draft),
                        ),
                        SizedBox(
                          width: materialFieldWidth,
                          child: _weightInput(
                            context,
                            controller: draft.spoolWeightController,
                            label: 'Peso del carrete',
                            hint: '1kg, un kilo y medio, 500 g',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (draft.selectedMaterial == _otro ||
                    draft.selectedColor == _otro) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (draft.selectedMaterial == _otro)
                        field(_textInput(
                          context,
                          controller: draft.manualMaterialController,
                          label: 'Escribe el material',
                          hint: 'Ej. PLA con fibra de carbono',
                        )),
                      if (draft.selectedColor == _otro)
                        field(_manualColorInput(context, draft)),
                    ],
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Divider(height: 1),
                ),
                _formSectionTitle(context, 'Urgencia en el laboratorio',
                    icon: Icons.bolt_rounded),
                Text(
                  'Prioridad para la reposición o compra de este material en el laboratorio.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: orderUrgencyDropdownWidth,
                    child: _urgencyDropdown(
                      context,
                      key: ValueKey('urgency_order_${draft.id}'),
                      selectedUrgency: draft.selectedUrgency,
                      onChanged: (value) =>
                          setState(() => draft.selectedUrgency = value),
                    ),
                  ),
                ),
                if (draft.selectedUrgency != null) ...[
                  const SizedBox(height: 14),
                  _textInput(
                    context,
                    key: ValueKey('order_urgency_details_${draft.id}'),
                    controller: draft.urgencyDetailsController,
                    label: 'Detalle y Texto de Urgencia',
                    hint:
                        'Ej. Reposición urgente, ej. Falta para la entrega de mañana',
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    key: ValueKey('order_cost_container_${draft.id}'),
                    width: 220,
                    child: _textInput(
                      context,
                      key: ValueKey('order_cost_${draft.id}'),
                      controller: draft.costController,
                      label: 'Costo (\$)',
                      hint: '0',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (draftIndex == _orderDrafts.length - 1 && !_consumablesOnly)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 220,
                height: 40,
                child: Tooltip(
                  message: 'Agregar otro pedido',
                  child: OutlinedButton.icon(
                    key: ValueKey('add_order_draft_$draftIndex'),
                    onPressed: () =>
                        setState(() => _orderDrafts.add(_OrderDraft())),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Agregar otro pedido'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF4F6F9),
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE5E7EB),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              addConsumablesButton(),
            ],
          ),
        if (draftIndex == _orderDrafts.length - 1 && !_consumablesOnly)
          const SizedBox(height: 18),
        if (draftIndex == _orderDrafts.length - 1 &&
            (_consumablesOnly || _consumablesVisible))
          Container(
            key: ValueKey('consumables_panel_${sharedDraft.id}'),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1E26) : const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : const Color(0xFFE9EBEF),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _formSectionTitle(
                        context,
                        'Consumibles',
                        icon: Icons.construction_outlined,
                      ),
                    ),
                    if (_consumablesOnly)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: isDark ? 0.16 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Pedido 1',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (!_consumablesOnly)
                      IconButton(
                        key: const ValueKey('hide_consumables_button'),
                        tooltip: 'Ocultar consumibles',
                        onPressed: () =>
                            setState(() => _consumablesVisible = false),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                Text(
                  'Boquillas, pegamento o piezas de repuesto adicionales (opcional).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                ...sharedDraft.consumableForms.asMap().entries.map((entry) {
                  final index = entry.key;
                  final form = entry.value;
                  return Container(
                    key: ValueKey('consumable_card_${sharedDraft.id}_$index'),
                    margin: EdgeInsets.only(
                      bottom: index == sharedDraft.consumableForms.length - 1
                          ? 0
                          : 14,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.025)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E7EF),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Consumible ${index + 1}',
                                key: ValueKey(
                                  'consumable_title_${sharedDraft.id}_$index',
                                ),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (index > 0)
                              IconButton(
                                key: ValueKey(
                                  'remove_consumable_${sharedDraft.id}_$index',
                                ),
                                tooltip: 'Quitar consumible',
                                onPressed: () => setState(() {
                                  sharedDraft.consumableForms
                                      .removeAt(index)
                                      .dispose();
                                }),
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                ),
                                color: theme.colorScheme.error,
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _textInput(
                          context,
                          key: ValueKey(
                            'consumable_link_${sharedDraft.id}_$index',
                          ),
                          controller: form.linkController,
                          label: 'Link de donde se encontró el consumible',
                          hint: 'https://...',
                          keyboardType: TextInputType.url,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Pegar enlace del consumible',
                                onPressed: () async {
                                  final data = await Clipboard.getData(
                                    Clipboard.kTextPlain,
                                  );
                                  if (data?.text != null &&
                                      data!.text!.trim().isNotEmpty) {
                                    form.linkController.text =
                                        data.text!.trim();
                                    setState(() {});
                                  }
                                },
                                icon: const Icon(
                                  Icons.content_paste_rounded,
                                  size: 20,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Abrir enlace del consumible',
                                onPressed: () =>
                                    _openPageLink(form.linkController.text),
                                icon: const Icon(
                                  Icons.open_in_browser_rounded,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final selectorWidth = constraints.maxWidth >= 620
                                ? (constraints.maxWidth - 12) / 2
                                : constraints.maxWidth;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.start,
                              children: [
                                SizedBox(
                                  width: selectorWidth,
                                  child: _dropdown(
                                    context,
                                    key: ValueKey(
                                      'consumable_dropdown_${sharedDraft.id}_$index',
                                    ),
                                    value: form.selected,
                                    options: [..._consumables, _otro],
                                    hint: 'Elegir consumible',
                                    label: 'Tipo de consumible',
                                    onChanged: (value) =>
                                        setState(() => form.selected = value),
                                  ),
                                ),
                                SizedBox(
                                  width: selectorWidth,
                                  child: _textInput(
                                    context,
                                    key: ValueKey(
                                      'consumable_quantity_${sharedDraft.id}_$index',
                                    ),
                                    controller: form.quantityController,
                                    label: 'Cantidad',
                                    hint: 'Ej. 5 litros o 10 piezas',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (form.selected == _otro) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: consumableSelectorWidth,
                            child: _textInput(
                              context,
                              key: ValueKey(
                                'consumable_manual_${sharedDraft.id}_$index',
                              ),
                              controller: form.manualController,
                              label: 'Escribe el consumible',
                              hint: 'Ej. Boquilla de 0.4 mm',
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _buildConsumableUrgencyForm(
                          context,
                          form,
                          index,
                          availableWidth: availableWidth,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          key: ValueKey(
                            'consumable_cost_container_${sharedDraft.id}_$index',
                          ),
                          width: 295,
                          child: _textInput(
                            context,
                            key: ValueKey(
                              'consumable_cost_${sharedDraft.id}_$index',
                            ),
                            controller: form.costController,
                            label: 'Costo (\$)',
                            hint: '0',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        if (draftIndex == _orderDrafts.length - 1 && _consumablesOnly)
          const SizedBox(height: 16),
        if (draftIndex == _orderDrafts.length - 1 && _consumablesOnly)
          Align(
            alignment: Alignment.centerLeft,
            child: addConsumablesButton(),
          ),
        if (draftIndex == _orderDrafts.length - 1 && _consumablesOnly)
          const SizedBox(height: 18),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1E26) : const Color(0xFFF9FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : const Color(0xFFE9EBEF),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      key: const ValueKey('submit_order_0'),
                      onPressed: _loading || _saving ? null : _addOrder,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Agregar a la tabla',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: const Color(0xFF0071E3),
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shadowColor:
                            const Color(0xFF0071E3).withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _macInputDecoration(
    BuildContext context, {
    String? hintText,
    Widget? suffixIcon,
    Color? customFill,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF757D8A) : const Color(0xFF9CA3AF),
        fontSize: 13,
      ),
      suffixIcon: suffixIcon,
      isDense: true,
      filled: true,
      fillColor: customFill ??
          (isDark ? const Color(0xFF20242D) : const Color(0xFFF5F6F9)),
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.8),
      ),
    );
  }

  Widget _formSectionTitle(
    BuildContext context,
    String title, {
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(
                  alpha: isDark ? 0.20 : 0.09,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                icon,
                size: 13,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: -0.2,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textInput(
    BuildContext context, {
    Key? key,
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: key,
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: theme.textTheme.bodyMedium,
          decoration: _macInputDecoration(
            context,
            hintText: hint,
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ],
    );
  }

  Widget _weightInput(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final grams = parseWeightToGrams(value.text);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _textInput(
              context,
              controller: controller,
              label: label,
              hint: hint,
              keyboardType: TextInputType.text,
            ),
            if (value.text.trim().isNotEmpty && grams != null) ...[
              const SizedBox(height: 4),
              Text(
                '= ${_formatWeight(grams)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _dropdown(
    BuildContext context, {
    Key? key,
    required String label,
    required String? value,
    required List<String> options,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final safeValue = value != null && options.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: key ?? ValueKey('material_$safeValue'),
          initialValue: safeValue,
          isExpanded: true,
          hint: Text(hint, overflow: TextOverflow.ellipsis),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: _macInputDecoration(
            context,
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ),
      ],
    );
  }

  Widget _filamentColorDropdown(BuildContext context, _OrderDraft draft) {
    final theme = Theme.of(context);
    final colorDraft = draft.manualColorController.text.trim();
    final options = [..._colors];
    if (colorDraft.isNotEmpty &&
        !_colors.any(
          (color) => color.toLowerCase() == colorDraft.toLowerCase(),
        )) {
      options.add(colorDraft);
    }
    options.add(_otro);
    final safeValue =
        draft.selectedColor != null && options.contains(draft.selectedColor)
            ? draft.selectedColor
            : null;
    Widget colorRow(String option, {bool selected = false}) => Row(
          children: [
            _filamentSwatch(
              option,
              key: ValueKey(
                selected
                    ? 'selected_filament_swatch'
                    : 'filament_palette_swatch_${option.toLowerCase()}',
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
          ],
        );
    Widget addColorRow() => const Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 18),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Agregar otro color',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
    final selectedItems = options.map((option) {
      if (option == _otro) {
        return addColorRow();
      }
      return colorRow(option, selected: true);
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color del filamento',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey('filament_color_${draft.id}_$safeValue'),
          initialValue: safeValue,
          isExpanded: true,
          menuMaxHeight: 360,
          hint: const Text('Elegir color'),
          items: options.map((option) {
            if (option == _otro) {
              return const DropdownMenuItem<String>(
                value: _otro,
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, size: 18),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Agregar otro color',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }
            return DropdownMenuItem<String>(
              value: option,
              child: colorRow(option),
            );
          }).toList(),
          selectedItemBuilder: (context) => selectedItems,
          onChanged: (value) => _selectFilamentColor(draft, value),
          decoration: _macInputDecoration(
            context,
            hintText: 'Elegir color',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ),
      ],
    );
  }

  Widget _filamentSwatch(
    String name, {
    double size = 20,
    required Key key,
  }) {
    final color = _filamentColor(name);
    return Container(
      key: key,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: color.computeLuminance() > 0.88
              ? const Color(0xFF9E9E9E)
              : Colors.black.withValues(alpha: 0.12),
        ),
      ),
    );
  }

  Widget _manualColorInput(BuildContext context, _OrderDraft draft) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textInput(
          context,
          controller: draft.manualColorController,
          label: 'Escribe un color nuevo',
          hint: 'Ej. Azul marino o #123ABC',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _filamentSwatch(
              draft.manualColorController.text,
              key: const ValueKey('filament_preview_swatch'),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                draft.manualColorController.text.trim().isEmpty
                    ? 'Vista previa del color'
                    : draft.manualColorController.text.trim(),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _saving ? null : () => _addCustomColorToPalette(draft),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Añadir a la paleta'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConsumableUrgencyForm(
    BuildContext context,
    _ConsumableForm form,
    int index, {
    required double availableWidth,
  }) {
    final theme = Theme.of(context);
    final urgencyDropdownWidth = availableWidth >= 620 ? 400.0 : availableWidth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formSectionTitle(context, 'Urgencia en el laboratorio',
            icon: Icons.bolt_rounded),
        Text(
          'Prioridad para la reposición o compra de este material en el laboratorio.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: urgencyDropdownWidth,
          child: _urgencyDropdown(
            context,
            key: ValueKey('urgency_consumable_${form.id}'),
            selectedUrgency: form.selectedUrgency,
            onChanged: (value) => setState(() => form.selectedUrgency = value),
          ),
        ),
        if (form.selectedUrgency != null) ...[
          const SizedBox(height: 14),
          _textInput(
            context,
            key: ValueKey('consumable_urgency_details_$index'),
            controller: form.urgencyDetailsController,
            label: 'Detalle y Texto de Urgencia',
            hint: 'Ej. Reposición urgente, ej. Falta para la entrega de mañana',
          ),
        ],
      ],
    );
  }

  Widget _urgencyDropdown(
    BuildContext context, {
    required Key key,
    String label = 'Urgencia en el laboratorio',
    bool compact = false,
    required String? selectedUrgency,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final selectedColor = selectedUrgency == null
        ? null
        : _urgencyColor(context, selectedUrgency);
    final selectedForeground =
        selectedUrgency == null ? theme.colorScheme.onSurface : Colors.white;
    final selector = compact
        ? DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: key,
              value: selectedUrgency,
              isDense: true,
              isExpanded: true,
              icon: const SizedBox.shrink(),
              selectedItemBuilder: (context) => ['Rojo', 'Amarillo', 'Verde']
                  .map(
                    (level) => Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _urgencyColor(context, level),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 9,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              level,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
              items: ['Rojo', 'Amarillo', 'Verde']
                  .map(
                    (level) => DropdownMenuItem<String>(
                      value: level,
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 13,
                            color: _urgencyColor(context, level),
                          ),
                          const SizedBox(width: 8),
                          Text(level),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          )
        : DropdownButtonFormField<String>(
            key: key,
            initialValue: selectedUrgency,
            isExpanded: true,
            hint: const Text('Elegir urgencia'),
            items: ['Rojo', 'Amarillo', 'Verde']
                .map(
                  (level) => DropdownMenuItem<String>(
                    value: level,
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 13,
                          color: _urgencyColor(context, level),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          level,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          level == 'Rojo'
                              ? '· Alta / Crítica'
                              : level == 'Amarillo'
                                  ? '· Media'
                                  : '· Baja',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            selectedItemBuilder: (context) => ['Rojo', 'Amarillo', 'Verde']
                .map(
                  (level) => Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        level,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
            onChanged: onChanged,
            decoration: _macInputDecoration(
              context,
              customFill: selectedColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            dropdownColor: theme.colorScheme.surface,
            iconEnabledColor: selectedForeground,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: selectedForeground,
              fontWeight: FontWeight.w500,
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        selector,
      ],
    );
  }

  Widget _buildOrdersTable(
    BuildContext context, {
    String title = 'Lista de pedidos',
    VoidCallback? onStateUpdate,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    void updateSelection(String bId) {
      _selectedBatchId = bId;
      if (mounted) setState(() {});
      onStateUpdate?.call();
    }

    // Agrupamos los pedidos conservando el orden de lote (más reciente primero)
    final groupsMap = <String, List<_MaterialOrder>>{};
    for (final order in _orders) {
      final key = order.effectiveBatchId;
      groupsMap.putIfAbsent(key, () => []).add(order);
    }
    final allBatchIds = groupsMap.keys.toList();

    // Si el lote seleccionado no existe o es nulo, seleccionamos el primero por defecto
    if (_selectedBatchId == null || !groupsMap.containsKey(_selectedBatchId)) {
      _selectedBatchId = allBatchIds.isNotEmpty ? allBatchIds.first : null;
    }

    final selectedGroupOrders = _selectedBatchId != null ? (groupsMap[_selectedBatchId] ?? <_MaterialOrder>[]) : <_MaterialOrder>[];

    var totalTableItems = 0;
    for (final order in _orders) {
      if (!order.isConsumableOnly) totalTableItems++;
      totalTableItems += order.consumableRequests.length;
    }

    return Container(
      key: const ValueKey('material_orders_list'),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A22) : const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE3E6EC),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado de la tarjeta
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.20 : 0.10),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.view_agenda_outlined,
                    size: 15,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (_orders.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${allBatchIds.length} ${allBatchIds.length == 1 ? "pedido" : "pedidos"} ($totalTableItems ítems)',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE3E6EC),
          ),
          if (_orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aún no hay pedidos registrados',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completa el formulario para agregar insumos y carretes.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;
                if (isNarrow) {
                  return _buildNarrowMasterDetailView(
                    context,
                    allBatchIds: allBatchIds,
                    groupsMap: groupsMap,
                    selectedBatchId: _selectedBatchId,
                    selectedOrders: selectedGroupOrders,
                    onSelectBatch: updateSelection,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Panel izquierdo: Lista de lotes
                      SizedBox(
                        width: 240,
                        child: _LoteListView(
                          batchIds: allBatchIds,
                          groupsMap: groupsMap,
                          selectedBatchId: _selectedBatchId,
                          formatOrderDate: _formatOrderDate,
                          onSelectBatch: updateSelection,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Panel derecho: Detalle del lote
                      Expanded(
                        child: _LoteDetalle(
                          batchId: _selectedBatchId ?? '',
                          orders: selectedGroupOrders,
                          formatOrderDate: _formatOrderDate,
                          onOpenLink: _openPageLink,
                          siteName: _siteName,
                          formatWeight: _formatWeight,
                          filamentColor: _filamentColor,
                          consumableIcon: _consumableCategoryIcon,
                          onEditBatch: () => _editBatch(_selectedBatchId ?? ''),
                          onDeleteBatch: () => _confirmDeleteBatch(_selectedBatchId ?? ''),
                          onEditOrder: _editOrder,
                          onRemoveOrder: _removeOrder,
                          onShowOrderDetails: _showOrderDetails,
                          onEditConsumable: _editConsumable,
                          onRemoveConsumable: _removeConsumable,
                          onExportBatchWord: (batchId) {
                            _exportOrdersToWord(specificBatchId: batchId);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNarrowMasterDetailView(
    BuildContext context, {
    required List<String> allBatchIds,
    required Map<String, List<_MaterialOrder>> groupsMap,
    required String? selectedBatchId,
    required List<_MaterialOrder> selectedOrders,
    required ValueChanged<String> onSelectBatch,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: _LoteListView(
        batchIds: allBatchIds,
        groupsMap: groupsMap,
        selectedBatchId: selectedBatchId,
        formatOrderDate: _formatOrderDate,
        onSelectBatch: (bId) {
          onSelectBatch(bId);
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (sheetContext) {
              return DraggableScrollableSheet(
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (_, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E222B)
                          : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: _LoteDetalle(
                              batchId: bId,
                              orders: groupsMap[bId] ?? [],
                              formatOrderDate: _formatOrderDate,
                              onOpenLink: _openPageLink,
                              siteName: _siteName,
                              formatWeight: _formatWeight,
                              filamentColor: _filamentColor,
                              consumableIcon: _consumableCategoryIcon,
                              onEditBatch: () {
                                Navigator.of(sheetContext).pop();
                                _editBatch(bId);
                              },
                              onDeleteBatch: () {
                                Navigator.of(sheetContext).pop();
                                _confirmDeleteBatch(bId);
                              },
                              onEditOrder: _editOrder,
                              onRemoveOrder: (order) async {
                                Navigator.of(sheetContext).pop();
                                await _removeOrder(order);
                              },
                              onShowOrderDetails: _showOrderDetails,
                              onEditConsumable: _editConsumable,
                              onRemoveConsumable: (order, idx) async {
                                Navigator.of(sheetContext).pop();
                                await _removeConsumable(order, idx);
                              },
                              onExportBatchWord: (_) {
                                Navigator.of(sheetContext).pop();
                                _exportOrdersToWord(specificBatchId: bId);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteBatch(String batchId) async {
    final batchOrders = _orders.where((o) => o.effectiveBatchId == batchId).toList();
    if (batchOrders.isEmpty) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22),
        actionsPadding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: isDark ? 0.20 : 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Eliminar pedido',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este pedido completo con todos sus ítems? Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _orders.removeWhere((o) => o.effectiveBatchId == batchId);
        if (_selectedBatchId == batchId) {
          _selectedBatchId = null;
        }
      });
      await _saveData();
      _notifyOrdersChanged();
      _showMessage('Pedido eliminado correctamente.');
    }
  }

  Future<void> _editBatch(String batchId) async {
    final batchOrders = _orders.where((o) => o.effectiveBatchId == batchId).toList();
    if (batchOrders.isEmpty) return;

    // Recolectar todos los ítems editables del lote
    final items = <({bool isFilament, _MaterialOrder order, int consumableIndex, String title})>[];
    for (final order in batchOrders) {
      if (!order.isConsumableOnly && order.material.isNotEmpty) {
        items.add((
          isFilament: true,
          order: order,
          consumableIndex: -1,
          title: '${order.material} ${order.color}'.trim(),
        ));
      }
      for (var i = 0; i < order.consumableRequests.length; i++) {
        items.add((
          isFilament: false,
          order: order,
          consumableIndex: i,
          title: 'Insumo: ${order.consumableRequests[i].name}',
        ));
      }
    }

    if (items.isEmpty) return;

    if (items.length == 1) {
      final single = items.first;
      if (single.isFilament) {
        await _editOrder(single.order);
      } else {
        await _editConsumable(single.order, single.consumableIndex);
      }
      return;
    }

    // Si tiene múltiples ítems, mostrar un selector rápido y limpio para elegir cuál editar
    if (!mounted) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedIndex = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.20 : 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 19),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Selecciona el ítem a editar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++)
                ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: Icon(
                    items[i].isFilament ? Icons.circle : Icons.inventory_2_outlined,
                    size: 16,
                    color: items[i].isFilament
                        ? _filamentColor(items[i].order.color)
                        : const Color(0xFF2563EB),
                  ),
                  title: Text(
                    items[i].title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                  onTap: () => Navigator.of(dialogCtx).pop(i),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(null),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selectedIndex != null && selectedIndex >= 0 && selectedIndex < items.length) {
      final chosen = items[selectedIndex];
      if (chosen.isFilament) {
        await _editOrder(chosen.order);
      } else {
        await _editConsumable(chosen.order, chosen.consumableIndex);
      }
    }
  }

  Future<void> _showOrderDetails(
    _MaterialOrder order, {
    String? pageLink,
  }) {
    final theme = Theme.of(context);
    final orderPageLink = pageLink ?? order.link;
    final total = order.cost +
        order.consumableRequests.fold<double>(
          0,
          (sum, request) => sum + request.cost,
        );
    final invoiceItems = <Widget>[
      if (!order.isConsumableOnly)
        _invoiceLine(
          '${order.material} · ${order.color}'
          '${order.spoolGrams == null ? '' : ' · ${_formatWeight(order.spoolGrams!)}'}',
          order.cost,
        ),
      ...order.consumableRequests.map(
        (request) => _invoiceLine(
          '${request.name}${request.quantity.isEmpty ? '' : ' · ${request.quantity}'}',
          request.cost,
        ),
      ),
    ];

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: ValueKey('order_details_dialog_${order.id}'),
        title: const Text('Detalles del pedido y factura'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailLine('Fecha', _formatOrderDate(order.createdAt)),
                _detailPageLine(orderPageLink),
                if (!order.isConsumableOnly) ...[
                  _detailLine('Material', order.material),
                  _detailLine('Color', order.color),
                  _detailLine(
                    'Peso',
                    order.spoolGrams == null
                        ? 'No especificado'
                        : _formatWeight(order.spoolGrams!),
                  ),
                  _detailLine(
                    'Peso restante',
                    order.remainingGrams == null
                        ? 'No disponible'
                        : _formatWeight(order.remainingGrams!),
                  ),
                ],
                _detailLine(
                  'Urgencia',
                  '${order.urgency} · ${order.urgencyType}: '
                      '${order.urgencyDetails}',
                ),
                const SizedBox(height: 20),
                Text(
                  'Factura',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ...invoiceItems,
                const Divider(height: 24),
                _invoiceLine('Total', total, isTotal: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _detailPageLine(String link) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              'Página',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: link.isEmpty
                ? Text(
                    'Sin enlace',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Tooltip(
                    message: link,
                    child: TextButton.icon(
                      key: const ValueKey('order_details_page_link'),
                      onPressed: () => _openPageLink(link),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: Text(
                        link,
                        textAlign: TextAlign.left,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceLine(
    String description,
    double amount, {
    bool isTotal = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.w800 : null,
              ),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isTotal ? theme.colorScheme.primary : null,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  IconData _consumableCategoryIcon(String name) {
    final lower = name.trim().toLowerCase();
    if (lower.contains('nozzle') || lower.contains('boquilla') || lower.contains('hotend') || lower.contains('bloque') || lower.contains('garganta')) {
      return Icons.hardware_rounded;
    } else if (lower.contains('cama') || lower.contains('bed') || lower.contains('pei') || lower.contains('vidrio') || lower.contains('placa') || lower.contains('lamina')) {
      return Icons.crop_portrait_rounded;
    } else if (lower.contains('tubo') || lower.contains('ptfe') || lower.contains('bowden') || lower.contains('manguera')) {
      return Icons.linear_scale_rounded;
    } else if (lower.contains('alcohol') || lower.contains('isoprop') || lower.contains('pegamento') || lower.contains('laca') || lower.contains('resina') || lower.contains('limpiador')) {
      return Icons.sanitizer_rounded;
    } else if (lower.contains('termistor') || lower.contains('sensor') || lower.contains('resistencia') || lower.contains('cable') || lower.contains('motor') || lower.contains('placa base')) {
      return Icons.electric_bolt_rounded;
    } else if (lower.contains('ventilador') || lower.contains('fan') || lower.contains('cooler') || lower.contains('disipador')) {
      return Icons.air_rounded;
    } else if (lower.contains('correa') || lower.contains('polea') || lower.contains('rodamiento') || lower.contains('guia') || lower.contains('husillo') || lower.contains('tornillo')) {
      return Icons.settings_rounded;
    } else if (lower.contains('filtro') || lower.contains('hepa') || lower.contains('carbon')) {
      return Icons.filter_alt_outlined;
    } else if (lower.contains('espatula') || lower.contains('pinza') || lower.contains('alicates') || lower.contains('llave') || lower.contains('herramienta') || lower.contains('calibrador')) {
      return Icons.handyman_rounded;
    }
    return Icons.build_circle_outlined;
  }

  String _formatOrderDate(DateTime? date) {
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _exportOrdersToWord({String? specificBatchId, bool onlyLastBatch = false}) async {
    if (_orders.isEmpty) {
      _showMessage('No hay pedidos en la tabla para exportar.', isError: true);
      return;
    }

    // Identificar los pedidos objetivo:
    // Si viene un lote específico (el botón Exportar Word de ese pedido), se exporta directamente ese lote.
    // De lo contrario, si onlyLastBatch es true se usa el último lote, o si no todos.
    final List<_MaterialOrder> targetOrders;
    if (specificBatchId != null && specificBatchId.isNotEmpty) {
      targetOrders = _orders.where((o) => o.effectiveBatchId == specificBatchId).toList();
    } else if (onlyLastBatch && _lastSubmittedBatchIds.isNotEmpty) {
      final lastBatches = _orders
          .where((o) => _lastSubmittedBatchIds.contains(o.id))
          .map((o) => o.effectiveBatchId)
          .toSet();
      targetOrders = _orders.where((o) => lastBatches.contains(o.effectiveBatchId)).toList();
    } else {
      targetOrders = List<_MaterialOrder>.from(_orders);
    }

    if (targetOrders.isEmpty) {
      _showMessage('No hay ítems para exportar en este pedido.', isError: true);
      return;
    }

    // Conteos rápidos para el resumen del diálogo
    var totalFilaments = 0;
    var totalConsumables = 0;
    var totalCost = 0.0;
    for (final o in targetOrders) {
      if (!o.isConsumableOnly && o.material.isNotEmpty) {
        totalFilaments++;
        totalCost += o.cost;
      }
      totalConsumables += o.consumableRequests.length;
      for (final r in o.consumableRequests) {
        totalCost += r.cost;
      }
    }

    final year = DateTime.now().year;
    final oficioController =
        TextEditingController(text: 'OFICIO No.: P. XXXX/$year');
    final asuntoController = TextEditingController(
      text: 'Solicitud de Materiales e Insumos para Laboratorio 3D',
    );
    DateTime selectedDate = DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final colors = Theme.of(context).colorScheme;
          final formattedDate =
              '${selectedDate.day}/${WordInventoryExporter.spanishMonths[selectedDate.month - 1]}/${selectedDate.year}';

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
              ),
            ),
            titlePadding: const EdgeInsets.fromLTRB(22, 18, 16, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 22),
            actionsPadding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF3B82F6), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Exportar Solicitud a Word (.docx)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(dlgCtx).pop(false),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Cerrar',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tarjeta informativa de los ítems que se van a exportar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161A22) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: colors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Se exportarán: $totalFilaments carretes y $totalConsumables insumos (Total: \$${totalCost.toStringAsFixed(2)}).',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Selector de Fecha
                    Text(
                      'Fecha del oficio',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDlgState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF20242D) : const Color(0xFFF5F6F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16),
                            const SizedBox(width: 10),
                            Text(
                              formattedDate,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_calendar_outlined, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Número de Oficio
                    Text(
                      'Número de Oficio (opcional)',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: oficioController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _macInputDecoration(
                        context,
                        hintText: 'OFICIO No.: P. XXXX/$year',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Asunto del oficio
                    Text(
                      'Asunto del oficio',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: asuntoController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _macInputDecoration(
                        context,
                        hintText: 'Asunto de la solicitud...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dlgCtx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(dlgCtx).pop(true),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Generar Word (.docx)'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    try {
      final inst = InstitutionalSettings.instance;
      await inst.load();

      final materialReportItems = <MaterialOrderReportItem>[];
      final consumableReportItems = <ConsumableOrderReportItem>[];

      for (final order in targetOrders) {
        if (!order.isConsumableOnly && order.material.trim().isNotEmpty) {
          materialReportItems.add(
            MaterialOrderReportItem(
              material: order.material,
              color: order.color,
              spoolGrams: order.spoolGrams,
              urgency: order.urgency,
              urgencyDetails: order.urgencyDetails,
              cost: order.cost,
            ),
          );
        }

        for (final req in order.consumableRequests) {
          consumableReportItems.add(
            ConsumableOrderReportItem(
              name: req.name,
              quantity: req.quantity,
              urgency: req.urgency,
              urgencyDetails: req.urgencyDetails,
              cost: req.cost,
            ),
          );
        }
      }

      final config = WordInventoryReportConfig(
        date: selectedDate,
        oficioNo: oficioController.text.trim(),
        directorName: inst.directorName,
        directorRole: inst.directorRole,
        encargadoName: inst.encargadoName,
        encargadoRole: inst.encargadoRole,
        remitenteName: inst.remitenteName,
        remitenteRole: inst.remitenteRole,
        ccp1: inst.ccp1,
        ccp2: inst.ccp2,
      );

      final bytes = await WordInventoryExporter.generateOrderRequestDocx(
        materialOrders: materialReportItems,
        consumableOrders: consumableReportItems,
        config: config,
        asuntoCustom: asuntoController.text.trim(),
      );

      const prefix = 'SOLICITUD_PEDIDO_MATERIALES';
      final fileName =
          '${prefix}_${selectedDate.day}_${selectedDate.month}_${selectedDate.year}.docx';

      final isDesktop = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS);

      if (isDesktop) {
        final location = await getSaveLocation(
          suggestedName: fileName,
          acceptedTypeGroups: const [
            XTypeGroup(label: 'DOCX', extensions: ['docx']),
          ],
        );
        if (location == null) return;
        await XFile.fromData(
          Uint8List.fromList(bytes),
          name: fileName,
          mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ).saveTo(location.path);
      } else {
        await share_plus.SharePlus.instance.share(
          share_plus.ShareParams(
            files: [
              share_plus.XFile.fromData(
                Uint8List.fromList(bytes),
                mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
              ),
            ],
            fileNameOverrides: [fileName],
            downloadFallbackEnabled: true,
          ),
        );
      }

      if (!mounted) return;
      _showMessage('Solicitud en Word (.docx) generada exitosamente.');
    } catch (e, st) {
      debugPrint('Error exportando reporte Word de pedidos: $e\n$st');
      if (!mounted) return;
      _showMessage('Error al generar archivo Word: $e', isError: true);
    }
  }

  Widget _buildStorageWarning(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _storageError!,
        style: TextStyle(color: theme.colorScheme.onErrorContainer),
      ),
    );
  }

  BoxDecoration _cardDecoration(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE8EAEE),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: isDark ? 0.35 : 0.04,
          ),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(
            alpha: isDark ? 0.20 : 0.015,
          ),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  Color _urgencyColor(BuildContext context, String urgency) {
    switch (urgency) {
      case 'Rojo':
        return const Color(0xFFDC2626);
      case 'Amarillo':
        return const Color(0xFFFACC15);
      case 'Verde':
        return const Color(0xFF15803D);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _filamentColor(String name) {
    final normalized = name.trim().toLowerCase();
    final hex = normalized.startsWith('#') ? normalized.substring(1) : '';
    if (hex.length == 6 || hex.length == 8) {
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        return Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
      }
    }
    for (final paletteColor in voxelColorPalette) {
      if (paletteColor.name.toLowerCase() == normalized) {
        return paletteColor.color;
      }
    }
    switch (normalized) {
      case 'negro':
      case 'black':
        return const Color(0xFF111111);
      case 'blanco':
      case 'white':
        return const Color(0xFFFFFFFF);
      case 'gris':
      case 'gray':
      case 'grey':
        return const Color(0xFF808080);
      case 'rojo':
      case 'red':
        return const Color(0xFFE53935);
      case 'azul':
        return const Color(0xFF1E88E5);
      case 'azul de prusia':
      case 'prussian blue':
        return const Color(0xFF003153);
      case 'azul marino':
      case 'navy':
        return const Color(0xFF001F3F);
      case 'azul cielo':
      case 'sky blue':
        return const Color(0xFF4FC3F7);
      case 'verde':
      case 'green':
        return const Color(0xFF43A047);
      case 'verde lima':
      case 'lime green':
        return const Color(0xFF8BC34A);
      case 'amarillo':
        return const Color(0xFFFDD835);
      case 'ocre amarillo':
      case 'yellow ochre':
        return const Color(0xFFCC7722);
      case 'naranja':
      case 'orange':
        return const Color(0xFFFB8C00);
      case 'rosa':
      case 'pink':
        return const Color(0xFFE91E63);
      case 'morado':
      case 'púrpura':
      case 'purple':
        return const Color(0xFF7E57C2);
      case 'turquesa':
      case 'turquoise':
        return const Color(0xFF26A69A);
      case 'beige':
        return const Color(0xFFD7CCC8);
      case 'café':
      case 'cafe':
        return const Color(0xFF795548);
      case 'transparente':
        return Colors.transparent;
      case 'marrón van dyke':
      case 'vandyke brown':
        return const Color(0xFF8B3F2F);
      case 'marrón':
      case 'brown':
        return const Color(0xFFA94F3D);
      case 'oro':
      case 'dorado':
      case 'gold':
      case 'golden':
        return voxelColorPalette
            .firstWhere((color) => color.name == 'Oro')
            .color;
      case 'silver':
      case 'plata':
      case 'plateado':
        return voxelColorPalette
            .firstWhere((color) => color.name == 'Silver')
            .color;
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _siteName(String link) {
    final uri = Uri.tryParse(link);
    return uri?.host.isNotEmpty == true ? uri!.host : link;
  }

  String _formatWeight(double grams) {
    final normalized = grams.roundToDouble();
    final formattedGrams = normalized == grams
        ? normalized.toStringAsFixed(0)
        : grams.toStringAsFixed(1);
    if (grams >= 1000) {
      final kilograms = grams / 1000;
      final formattedKilograms = kilograms == kilograms.roundToDouble()
          ? kilograms.toStringAsFixed(0)
          : kilograms.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
      return '$formattedKilograms kg ($formattedGrams g)';
    }
    return '$formattedGrams g';
  }
}

class _MaterialOrder {
  const _MaterialOrder({
    required this.id,
    required this.createdAt,
    required this.link,
    required this.material,
    required this.color,
    required this.urgency,
    required this.urgencyType,
    required this.urgencyDetails,
    required this.consumables,
    required this.consumableRequests,
    required this.spoolGrams,
    required this.usedGrams,
    required this.cost,
    this.isConsumableOnly = false,
    String? batchId,
  }) : batchId = batchId ?? '';

  final String id;
  final String batchId;
  final DateTime? createdAt;
  final String link;
  final String material;
  final String color;
  final String urgency;
  final String urgencyType;
  final String urgencyDetails;
  final List<String> consumables;
  final List<_ConsumableRequest> consumableRequests;
  final double? spoolGrams;
  final double? usedGrams;
  final double cost;
  final bool isConsumableOnly;

  String get effectiveBatchId {
    if (batchId.isNotEmpty) return batchId;
    return id.split('_').first;
  }

  double? get remainingGrams {
    if (spoolGrams == null) return null;
    return (spoolGrams! - (usedGrams ?? 0)).clamp(0, spoolGrams!).toDouble();
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'batchId': effectiveBatchId,
        'createdAt': createdAt?.toIso8601String(),
        'link': link,
        'material': material,
        'color': color,
        'urgency': urgency,
        'urgencyType': urgencyType,
        'urgencyDetails': urgencyDetails,
        'consumables': consumables,
        'consumableRequests':
            consumableRequests.map((request) => request.toJson()).toList(),
        'spoolGrams': spoolGrams,
        'usedGrams': usedGrams,
        'cost': cost,
        'isConsumableOnly': isConsumableOnly,
      };

  factory _MaterialOrder.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final savedBatchId = json['batchId'] as String?;
    final savedCreatedAt = json['createdAt'];
    final link = json['link'];
    final material = json['material'];
    final color = json['color'];
    final urgency = json['urgency'];
    final urgencyType = json['urgencyType'] ?? urgency;
    final urgencyDetails = json['urgencyDetails'];
    final savedConsumables = json['consumables'];
    final savedConsumableRequests = json['consumableRequests'];
    final legacyConsumable = json['consumable'];
    final cost = json['cost'];
    final isConsumableOnly = json['isConsumableOnly'] ?? false;
    if (id is! String ||
        (savedCreatedAt != null && savedCreatedAt is! String) ||
        link is! String ||
        material is! String ||
        color is! String ||
        urgency is! String ||
        urgencyType is! String ||
        urgencyDetails is! String ||
        (savedConsumables != null &&
            (savedConsumables is! List ||
                savedConsumables.any((item) => item is! String))) ||
        (savedConsumableRequests != null && savedConsumableRequests is! List) ||
        (legacyConsumable != null && legacyConsumable is! String) ||
        (cost is! num) ||
        isConsumableOnly is! bool) {
      throw const FormatException('Los datos de un pedido no son válidos.');
    }
    final legacyTimestamp = int.tryParse(id.split('_').first);
    final createdAt = savedCreatedAt is String
        ? DateTime.tryParse(savedCreatedAt)
        : legacyTimestamp == null
            ? null
            : DateTime.fromMicrosecondsSinceEpoch(legacyTimestamp);
    if (savedCreatedAt is String && createdAt == null) {
      throw const FormatException('La fecha de un pedido no es válida.');
    }
    final consumables = savedConsumables is List
        ? savedConsumables.cast<String>()
        : legacyConsumable is String
            ? [legacyConsumable]
            : const <String>[];
    final consumableRequests = savedConsumableRequests is List
        ? savedConsumableRequests.map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'Los datos de un consumible no son válidos.',
              );
            }
            return _ConsumableRequest.fromJson(item);
          }).toList()
        : consumables
            .map(
              (name) => _ConsumableRequest(
                name: name,
                quantity: '',
                link: null,
                urgency: urgency,
                urgencyType: urgencyType,
                urgencyDetails: urgencyDetails,
                cost: 0,
              ),
            )
            .toList();
    return _MaterialOrder(
      id: id,
      batchId: savedBatchId ?? (legacyTimestamp != null ? '$legacyTimestamp' : id.split('_').first),
      createdAt: createdAt,
      link: link,
      material: material,
      color: color,
      urgency: urgency,
      urgencyType: urgencyType,
      urgencyDetails: urgencyDetails,
      consumables: consumables,
      consumableRequests: consumableRequests,
      spoolGrams: _readNullableNumber(json['spoolGrams']),
      usedGrams: _readNullableNumber(json['usedGrams']),
      cost: cost.toDouble(),
      isConsumableOnly: isConsumableOnly,
    );
  }
}

class _ConsumableRequest {
  const _ConsumableRequest({
    required this.name,
    required this.quantity,
    required this.link,
    required this.urgency,
    required this.urgencyType,
    required this.urgencyDetails,
    required this.cost,
  });

  final String name;
  final String quantity;
  final String? link;
  final String urgency;
  final String urgencyType;
  final String urgencyDetails;
  final double cost;

  Map<String, Object?> toJson() => {
        'name': name,
        'quantity': quantity,
        'link': link,
        'urgency': urgency,
        'urgencyType': urgencyType,
        'urgencyDetails': urgencyDetails,
        'cost': cost,
      };

  factory _ConsumableRequest.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final quantity = json['quantity'] ?? '';
    final link = json['link'];
    final urgency = json['urgency'];
    final urgencyType = json['urgencyType'];
    final urgencyDetails = json['urgencyDetails'];
    final cost = json['cost'] ?? 0;
    if (link != null && link is! String) {
      throw const FormatException('Los datos de un consumible no son válidos.');
    }
    if (name is! String ||
        quantity is! String ||
        urgency is! String ||
        urgencyType is! String ||
        urgencyDetails is! String ||
        cost is! num ||
        cost < 0) {
      throw const FormatException('Los datos de un consumible no son válidos.');
    }
    return _ConsumableRequest(
      name: name,
      quantity: quantity,
      link: link,
      urgency: urgency,
      urgencyType: urgencyType,
      urgencyDetails: urgencyDetails,
      cost: cost.toDouble(),
    );
  }
}

class _FilamentSpoolIcon extends StatelessWidget {
  const _FilamentSpoolIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final color =
        IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return CustomPaint(
      size: const Size(20, 20),
      painter: _FilamentSpoolPainter(color),
    );
  }
}

class _FilamentSpoolPainter extends CustomPainter {
  const _FilamentSpoolPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawOval(const Rect.fromLTWH(4, 3, 16, 4), outline);
    canvas.drawLine(const Offset(4, 5), const Offset(4, 19), outline);
    canvas.drawLine(const Offset(20, 5), const Offset(20, 19), outline);
    canvas.drawArc(
      const Rect.fromLTWH(4, 17, 16, 4),
      0,
      3.14159,
      false,
      outline,
    );
    for (final y in [8.0, 10.5, 13.0, 15.5]) {
      canvas.drawLine(Offset(5, y), Offset(19, y), outline);
    }
    canvas.drawOval(const Rect.fromLTWH(8.5, 2, 7, 3), outline);
    canvas.drawOval(const Rect.fromLTWH(10, 2.5, 4, 2), outline);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FilamentSpoolPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _OrderDraft {
  static int _nextId = 0;

  _OrderDraft() : id = _nextId++;

  final int id;
  final linkController = TextEditingController();
  final manualMaterialController = TextEditingController();
  final manualColorController = TextEditingController();
  final urgencyDetailsController = TextEditingController();
  final spoolWeightController = TextEditingController();
  final costController = TextEditingController(text: '0');
  final List<_ConsumableForm> consumableForms = [_ConsumableForm()];

  String? selectedMaterial;
  String? selectedColor;
  String? selectedUrgency = 'Rojo';

  void dispose() {
    linkController.dispose();
    manualMaterialController.dispose();
    manualColorController.dispose();
    urgencyDetailsController.dispose();
    spoolWeightController.dispose();
    costController.dispose();
    for (final consumable in consumableForms) {
      consumable.dispose();
    }
  }
}

class _OrderEditDraft {
  _OrderEditDraft(_MaterialOrder order)
      : originalOrder = order,
        linkController = TextEditingController(text: order.link),
        materialController = TextEditingController(text: order.material),
        colorController = TextEditingController(text: order.color),
        weightController = TextEditingController(
          text: order.spoolGrams == null ? '' : '${order.spoolGrams} g',
        ),
        urgencyDetailsController = TextEditingController(
          text: _joinUrgencyDescription(
            order.urgencyType,
            order.urgencyDetails,
          ),
        ),
        costController =
            TextEditingController(text: order.cost.toStringAsFixed(2)),
        urgency = order.urgency,
        consumableDrafts = order.consumableRequests
            .map(_ConsumableEditDraft.fromRequest)
            .toList();

  _OrderEditDraft.empty()
      : originalOrder = null,
        linkController = TextEditingController(),
        materialController = TextEditingController(),
        colorController = TextEditingController(),
        weightController = TextEditingController(),
        urgencyDetailsController = TextEditingController(),
        costController = TextEditingController(text: '0'),
        urgency = 'Rojo',
        consumableDrafts = [];

  final _MaterialOrder? originalOrder;
  final TextEditingController linkController;
  final TextEditingController materialController;
  final TextEditingController colorController;
  final TextEditingController weightController;
  final TextEditingController urgencyDetailsController;
  final TextEditingController costController;
  final List<_ConsumableEditDraft> consumableDrafts;
  String? urgency;

  void dispose() {
    linkController.dispose();
    materialController.dispose();
    colorController.dispose();
    weightController.dispose();
    urgencyDetailsController.dispose();
    costController.dispose();
    for (final consumable in consumableDrafts) {
      consumable.dispose();
    }
  }
}

class _ConsumableEditDraft {
  _ConsumableEditDraft()
      : nameController = TextEditingController(),
        quantityController = TextEditingController(),
        linkController = TextEditingController(),
        costController = TextEditingController(text: '0'),
        urgencyDetailsController = TextEditingController();

  _ConsumableEditDraft.fromRequest(_ConsumableRequest request)
      : nameController = TextEditingController(text: request.name),
        quantityController = TextEditingController(text: request.quantity),
        linkController = TextEditingController(text: request.link ?? ''),
        costController =
            TextEditingController(text: request.cost.toStringAsFixed(2)),
        urgencyDetailsController = TextEditingController(
          text: _joinUrgencyDescription(
            request.urgencyType,
            request.urgencyDetails,
          ),
        ),
        urgency = request.urgency;

  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController linkController;
  final TextEditingController costController;
  final TextEditingController urgencyDetailsController;
  String? urgency = 'Rojo';

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    linkController.dispose();
    costController.dispose();
    urgencyDetailsController.dispose();
  }
}

class _ConsumableEditDraftDisposer extends StatefulWidget {
  const _ConsumableEditDraftDisposer({
    required this.draft,
    required this.child,
  });

  final _ConsumableEditDraft draft;
  final Widget child;

  @override
  State<_ConsumableEditDraftDisposer> createState() =>
      _ConsumableEditDraftDisposerState();
}

class _ConsumableEditDraftDisposerState
    extends State<_ConsumableEditDraftDisposer> {
  @override
  void dispose() {
    widget.draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ConsumableForm {
  static int _nextId = 0;

  _ConsumableForm()
      : id = _nextId++,
        selectedUrgency = 'Rojo';

  final int id;
  final linkController = TextEditingController();
  final quantityController = TextEditingController();
  final costController = TextEditingController(text: '0');
  final urgencyDetailsController = TextEditingController();

  String? selected;
  String? selectedUrgency;
  final TextEditingController manualController = TextEditingController();

  void dispose() {
    linkController.dispose();
    quantityController.dispose();
    costController.dispose();
    manualController.dispose();
    urgencyDetailsController.dispose();
  }
}

double? _readNullableNumber(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw const FormatException('El peso guardado no es válido.');
}

/// Convierte un peso en español a gramos.
///
/// Admite unidades explícitas, números solos (menos de 50 = kg) y cantidades
/// escritas con palabras, como "un kilo y medio" o "quinientos gramos".
double? parseWeightToGrams(String input) {
  var text = _normalizeSpanish(input);
  if (text.isEmpty) return null;

  final hasKilograms = RegExp(
    r'(?<![a-z])(kg|kilo|kilos|kilogramo|kilogramos)\b',
  ).hasMatch(text);
  final hasGrams = RegExp(
    r'(?<![a-z])(g|gr|gramo|gramos)\b',
  ).hasMatch(text);
  if (hasKilograms && hasGrams) return null;

  text = text
      .replaceAll(
        RegExp(r'(?<![a-z])(kilogramos?|kilos?|kg|gramos?|gr|g)\b'),
        ' ',
      )
      .replaceAll(RegExp(r'\b(de|del)\b'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (text.isEmpty) return null;

  var extraHalf = 0.0;
  final halfSuffix = RegExp(r'\s+y\s+medio(?:a)?$');
  if (halfSuffix.hasMatch(text)) {
    text = text.replaceFirst(halfSuffix, '').trim();
    extraHalf = 0.5;
  } else if (text == 'medio' || text == 'media') {
    text = '';
    extraHalf = 0.5;
  }

  double? amount;
  final numericMatch = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(text);
  if (numericMatch != null) {
    amount = double.tryParse(numericMatch.group(0)!.replaceAll(',', '.'));
    final rest = text.replaceFirst(numericMatch.group(0)!, '').trim();
    if (rest.isNotEmpty) return null;
  } else if (text.isNotEmpty) {
    amount = _parseSpanishNumber(text);
  } else {
    amount = 0;
  }

  if (amount == null || amount < 0) return null;
  amount += extraHalf;
  if (hasKilograms) return amount * 1000;
  if (hasGrams) return amount;
  return amount < 50 ? amount * 1000 : amount;
}

double? _parseSpanishNumber(String phrase) {
  final numberWords = <String, int>{
    'cero': 0,
    'un': 1,
    'uno': 1,
    'una': 1,
    'dos': 2,
    'tres': 3,
    'cuatro': 4,
    'cinco': 5,
    'seis': 6,
    'siete': 7,
    'ocho': 8,
    'nueve': 9,
    'diez': 10,
    'once': 11,
    'doce': 12,
    'trece': 13,
    'catorce': 14,
    'quince': 15,
    'dieciseis': 16,
    'diecisiete': 17,
    'dieciocho': 18,
    'diecinueve': 19,
    'veinte': 20,
    'veintiuno': 21,
    'veintiun': 21,
    'veintiuna': 21,
    'veintidos': 22,
    'veintitres': 23,
    'veinticuatro': 24,
    'veinticinco': 25,
    'veintiseis': 26,
    'veintisiete': 27,
    'veintiocho': 28,
    'veintinueve': 29,
    'treinta': 30,
    'cuarenta': 40,
    'cincuenta': 50,
    'sesenta': 60,
    'setenta': 70,
    'ochenta': 80,
    'noventa': 90,
    'cien': 100,
    'ciento': 100,
    'doscientos': 200,
    'trescientos': 300,
    'cuatrocientos': 400,
    'quinientos': 500,
    'seiscientos': 600,
    'setecientos': 700,
    'ochocientos': 800,
    'novecientos': 900,
  };

  final words = phrase.split(' ').where((word) => word != 'y').toList();
  if (words.isEmpty) return null;
  var total = 0;
  var current = 0;
  for (final word in words) {
    if (word == 'mil') {
      total += (current == 0 ? 1 : current) * 1000;
      current = 0;
      continue;
    }
    final value = numberWords[word];
    if (value == null) return null;
    current += value;
  }
  total += current;
  return total.toDouble();
}

String _normalizeSpanish(String input) {
  const replacements = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
  };
  var normalized = input.toLowerCase().trim();
  for (final entry in replacements.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }
  return normalized.replaceAll(RegExp(r'\s+'), ' ');
}

// ---------------------------------------------------------------------------
// MASTER-DETAIL: WIDGETS PARA LA LISTA DE PEDIDOS (LOTES)
// ---------------------------------------------------------------------------

class _LoteListView extends StatelessWidget {
  final List<String> batchIds;
  final Map<String, List<_MaterialOrder>> groupsMap;
  final String? selectedBatchId;
  final String Function(DateTime?) formatOrderDate;
  final ValueChanged<String> onSelectBatch;

  const _LoteListView({
    required this.batchIds,
    required this.groupsMap,
    required this.selectedBatchId,
    required this.formatOrderDate,
    required this.onSelectBatch,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: batchIds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final bId = batchIds[index];
        final ordersInBatch = groupsMap[bId] ?? const [];
        final isSelected = bId == selectedBatchId;

        // Calcular ítems, fecha y total del lote
        DateTime? date;
        var itemCount = 0;
        var totalCost = 0.0;
        for (final o in ordersInBatch) {
          date ??= o.createdAt;
          if (!o.isConsumableOnly && o.material.isNotEmpty) {
            itemCount++;
            totalCost += o.cost;
          }
          itemCount += o.consumableRequests.length;
          for (final c in o.consumableRequests) {
            totalCost += c.cost;
          }
        }

        return _LoteListItem(
          key: ValueKey('lote_item_$bId'),
          dateText: formatOrderDate(date),
          itemCount: itemCount,
          totalCost: totalCost,
          isSelected: isSelected,
          onTap: () => onSelectBatch(bId),
        );
      },
    );
  }
}

class _LoteListItem extends StatelessWidget {
  final String dateText;
  final int itemCount;
  final double totalCost;
  final bool isSelected;
  final VoidCallback onTap;

  const _LoteListItem({
    super.key,
    required this.dateText,
    required this.itemCount,
    required this.totalCost,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isSelected
        ? (isDark ? const Color(0xFF1E2B45) : const Color(0xFFEAF1FF))
        : (isDark ? const Color(0xFF1A1F2B) : Colors.white);

    final borderColor = isSelected
        ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.60 : 0.40)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE3E6EC));

    final totalFormatted = totalCost.truncateToDouble() == totalCost
        ? '\$${totalCost.toStringAsFixed(0)}'
        : '\$${totalCost.toStringAsFixed(2)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$itemCount ${itemCount == 1 ? "ítem" : "ítems"}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                totalFormatted,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoteDetalle extends StatelessWidget {
  final String batchId;
  final List<_MaterialOrder> orders;
  final String Function(DateTime?) formatOrderDate;
  final Future<void> Function(String) onOpenLink;
  final String Function(String) siteName;
  final String Function(double) formatWeight;
  final Color Function(String) filamentColor;
  final IconData Function(String) consumableIcon;
  final VoidCallback onEditBatch;
  final VoidCallback onDeleteBatch;
  final Future<void> Function(_MaterialOrder) onEditOrder;
  final Future<void> Function(_MaterialOrder) onRemoveOrder;
  final Future<void> Function(_MaterialOrder, {String? pageLink}) onShowOrderDetails;
  final Future<void> Function(_MaterialOrder, int) onEditConsumable;
  final Future<void> Function(_MaterialOrder, int) onRemoveConsumable;
  final void Function(String) onExportBatchWord;

  const _LoteDetalle({
    required this.batchId,
    required this.orders,
    required this.formatOrderDate,
    required this.onOpenLink,
    required this.siteName,
    required this.formatWeight,
    required this.filamentColor,
    required this.consumableIcon,
    required this.onEditBatch,
    required this.onDeleteBatch,
    required this.onEditOrder,
    required this.onRemoveOrder,
    required this.onShowOrderDetails,
    required this.onEditConsumable,
    required this.onRemoveConsumable,
    required this.onExportBatchWord,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    DateTime? batchDate;
    var totalCost = 0.0;
    final flatItems = <_LoteFlatItem>[];

    for (final order in orders) {
      batchDate ??= order.createdAt;
      if (!order.isConsumableOnly && order.material.isNotEmpty) {
        flatItems.add(_LoteFlatItem(
          isFilament: true,
          order: order,
          consumableIndex: -1,
          cost: order.cost,
        ));
        totalCost += order.cost;
      }
      for (var i = 0; i < order.consumableRequests.length; i++) {
        final req = order.consumableRequests[i];
        flatItems.add(_LoteFlatItem(
          isFilament: false,
          order: order,
          consumableIndex: i,
          consumable: req,
          cost: req.cost,
        ));
        totalCost += req.cost;
      }
    }

    final totalFormatted = totalCost.truncateToDouble() == totalCost
        ? '\$${totalCost.toStringAsFixed(0)}'
        : '\$${totalCost.toStringAsFixed(2)}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE3E6EC),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título del lote
          Text(
            'Detalle del pedido · ${formatOrderDate(batchDate)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 18),

          if (flatItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'Este lote no contiene ítems.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else ...[
            // Lista de ítems
            for (var i = 0; i < flatItems.length; i++) ...[
              _ItemRow(
                item: flatItems[i],
                siteName: siteName,
                filamentColor: filamentColor,
                consumableIcon: consumableIcon,
                onOpenLink: onOpenLink,
                onTapItem: () {
                  final it = flatItems[i];
                  if (it.isFilament) {
                    onShowOrderDetails(it.order);
                  } else {
                    onShowOrderDetails(
                      it.order,
                      pageLink: it.consumable?.link ?? it.order.link,
                    );
                  }
                },
              ),
              if (i < flatItems.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEFEFEF),
                  ),
                )
              else
                const SizedBox(height: 16),
            ],

            // Separador sutil o punteado antes del total
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE3E6EC),
            ),
            const SizedBox(height: 18),

            // Fila de Total
            Row(
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? Colors.white70 : const Color(0xFF475467),
                  ),
                ),
                const Spacer(),
                Text(
                  totalFormatted,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Botones de acción inferiores
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.start,
              children: [
                OutlinedButton(
                  key: const ValueKey('batch_action_edit'),
                  onPressed: onEditBatch,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Editar',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OutlinedButton(
                  key: const ValueKey('batch_action_delete'),
                  onPressed: onDeleteBatch,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Eliminar',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton(
                  key: const ValueKey('batch_action_export_word'),
                  onPressed: () => onExportBatchWord(batchId),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Exportar Word',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LoteFlatItem {
  final bool isFilament;
  final _MaterialOrder order;
  final int consumableIndex;
  final _ConsumableRequest? consumable;
  final double cost;

  const _LoteFlatItem({
    required this.isFilament,
    required this.order,
    required this.consumableIndex,
    this.consumable,
    required this.cost,
  });
}

class _ItemRow extends StatelessWidget {
  final _LoteFlatItem item;
  final String Function(String) siteName;
  final Color Function(String) filamentColor;
  final IconData Function(String) consumableIcon;
  final Future<void> Function(String) onOpenLink;
  final VoidCallback onTapItem;

  const _ItemRow({
    required this.item,
    required this.siteName,
    required this.filamentColor,
    required this.consumableIcon,
    required this.onOpenLink,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String name;
    final String link;
    final String urgency;
    final String reason;
    final String qtyOrWeight;
    final double? spoolGrams;
    final double? remainingGrams;

    if (item.isFilament) {
      name = '${item.order.material} ${item.order.color}'.trim();
      link = item.order.link;
      urgency = item.order.urgency;
      reason = item.order.urgencyDetails.trim().isNotEmpty
          ? item.order.urgencyDetails.trim()
          : item.order.urgencyType.trim();

      spoolGrams = item.order.spoolGrams;
      remainingGrams = item.order.remainingGrams;
      if (spoolGrams != null) {
        if (spoolGrams >= 1000) {
          final kg = spoolGrams / 1000;
          qtyOrWeight = kg == kg.roundToDouble()
              ? '${kg.toStringAsFixed(0)} kg'
              : '${kg.toStringAsFixed(1)} kg';
        } else {
          qtyOrWeight = '${spoolGrams.toStringAsFixed(0)} g';
        }
      } else {
        qtyOrWeight = '—';
      }
    } else {
      final req = item.consumable!;
      name = req.name.startsWith('Insumo') ? req.name : 'Insumo ${req.name}';
      link = req.link ?? item.order.link;
      urgency = req.urgency;
      reason = req.urgencyDetails.trim().isNotEmpty
          ? req.urgencyDetails.trim()
          : req.urgencyType.trim();
      qtyOrWeight = req.quantity.trim().isEmpty ? '1 pza' : req.quantity.trim();
      spoolGrams = null;
      remainingGrams = null;
    }

    final domain = siteName(link).trim();
    final costFormatted = item.cost.truncateToDouble() == item.cost
        ? '\$${item.cost.toStringAsFixed(0)}'
        : '\$${item.cost.toStringAsFixed(2)}';

    return InkWell(
      onTap: onTapItem,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icono o círculo a la izquierda
            if (item.isFilament)
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filamentColor(item.order.color),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFCBD5E1),
                    width: 1,
                  ),
                ),
              )
            else
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  consumableIcon(item.consumable?.name ?? ''),
                  size: 14,
                  color: const Color(0xFF2563EB),
                ),
              ),

            // Nombre y detalles secundarios (dominio clicable · motivo de urgencia)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name.isEmpty ? '—' : name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (link.isNotEmpty)
                        InkWell(
                          onTap: () => onOpenLink(link),
                          child: Text(
                            domain.isEmpty ? 'proveedor' : domain,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF667085),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF667085),
                            ),
                          ),
                        )
                      else
                        Text(
                          domain.isEmpty ? 'Sin enlace' : domain,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
                        ),
                      if (reason.isNotEmpty) ...[
                        const Text(
                          ' · ',
                          style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
                        ),
                        Flexible(
                          child: Text(
                            reason,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Urgencia chip con punto de color + texto siempre visible
            _UrgenciaChip(urgency: urgency),
            const SizedBox(width: 16),

            // Cantidad / Peso con barra de peso restante si es filamento
            SizedBox(
              width: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    qtyOrWeight,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.isFilament && spoolGrams != null && remainingGrams != null) ...[
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 50,
                        height: 3.5,
                        child: LinearProgressIndicator(
                          value: spoolGrams <= 0
                              ? 0.0
                              : (remainingGrams / spoolGrams).clamp(0.0, 1.0),
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 18),

            // Precio en negrita
            SizedBox(
              width: 80,
              child: Text(
                costFormatted,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgenciaChip extends StatelessWidget {
  final String urgency;

  const _UrgenciaChip({required this.urgency});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color dotColor;
    final Color bgColor;

    final lower = urgency.trim().toLowerCase();
    if (lower.contains('rojo') || lower.contains('alta')) {
      label = 'Alta';
      dotColor = const Color(0xFFEF4444); // Red
      bgColor = const Color(0xFFFEE2E2);
    } else if (lower.contains('amarillo') || lower.contains('media')) {
      label = 'Media';
      dotColor = const Color(0xFFF59E0B); // Amber
      bgColor = const Color(0xFFFEF3C7);
    } else {
      label = 'Baja';
      dotColor = const Color(0xFF10B981); // Emerald
      bgColor = const Color(0xFFD1FAE5);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? dotColor.withValues(alpha: 0.16) : bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : dotColor.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}
