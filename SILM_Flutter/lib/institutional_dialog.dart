import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'institutional_settings.dart';
import 'theme.dart';

class InstitutionalSettingsDialog extends StatefulWidget {
  const InstitutionalSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const InstitutionalSettingsDialog(),
    );
  }

  @override
  State<InstitutionalSettingsDialog> createState() =>
      _InstitutionalSettingsDialogState();
}

class _InstitutionalSettingsDialogState
    extends State<InstitutionalSettingsDialog> {
  int _selectedTab = 0; // 0: Firmas y Oficio, 1: Plantillas Oficiales

  final _directorCtrl = TextEditingController();
  final _directorRoleCtrl = TextEditingController();
  final _encargadoCtrl = TextEditingController();
  final _encargadoRoleCtrl = TextEditingController();
  final _remitenteCtrl = TextEditingController();
  final _remitenteRoleCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _lemaCtrl = TextEditingController();

  bool _loading = true;
  String? _customWordName;
  String? _customExcelName;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final inst = InstitutionalSettings.instance;
    await inst.load();
    if (mounted) {
      setState(() {
        _directorCtrl.text = inst.directorName;
        _directorRoleCtrl.text = inst.directorRole;
        _encargadoCtrl.text = inst.encargadoName;
        _encargadoRoleCtrl.text = inst.encargadoRole;
        _remitenteCtrl.text = inst.remitenteName;
        _remitenteRoleCtrl.text = inst.remitenteRole;
        _departmentCtrl.text = inst.department;
        _lemaCtrl.text = inst.lema;
        _customWordName = inst.customWordName;
        _customExcelName = inst.customExcelName;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _directorCtrl.dispose();
    _directorRoleCtrl.dispose();
    _encargadoCtrl.dispose();
    _encargadoRoleCtrl.dispose();
    _remitenteCtrl.dispose();
    _remitenteRoleCtrl.dispose();
    _departmentCtrl.dispose();
    _lemaCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    await InstitutionalSettings.instance.save(
      directorName: _directorCtrl.text,
      directorRole: _directorRoleCtrl.text,
      encargadoName: _encargadoCtrl.text,
      encargadoRole: _encargadoRoleCtrl.text,
      remitenteName: _remitenteCtrl.text,
      remitenteRole: _remitenteRoleCtrl.text,
      department: _departmentCtrl.text,
      lema: _lemaCtrl.text,
      ccp1: InstitutionalSettings.instance.ccp1,
      ccp2: InstitutionalSettings.instance.ccp2,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración institucional guardada correctamente'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // --- Manejo de Plantilla Word ---
  Future<void> _pickWordTemplate() async {
    const typeGroup = XTypeGroup(
      label: 'Documentos Word (*.docx)',
      extensions: ['docx'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    await InstitutionalSettings.instance.setCustomWordTemplate(bytes, file.name);

    if (mounted) {
      setState(() {
        _customWordName = file.name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plantilla Word cargada: ${file.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _downloadWordTemplate() async {
    final bytes = await InstitutionalSettings.instance.getWordTemplateBytes();
    final location = await getSaveLocation(
      suggestedName: _customWordName ?? 'plantilla_inventario_3d.docx',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'DOCX', extensions: ['docx']),
      ],
    );
    if (location == null) return;

    final target = File(location.path);
    await target.writeAsBytes(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plantilla descargada en: ${target.path}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetWordTemplate() async {
    await InstitutionalSettings.instance.resetWordTemplate();
    if (mounted) {
      setState(() {
        _customWordName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se restauró la plantilla Word predeterminada'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- Manejo de Plantilla Excel ---
  Future<void> _pickExcelTemplate() async {
    const typeGroup = XTypeGroup(
      label: 'Libros de Excel (*.xlsx)',
      extensions: ['xlsx'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    await InstitutionalSettings.instance.setCustomExcelTemplate(bytes, file.name);

    if (mounted) {
      setState(() {
        _customExcelName = file.name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plantilla Excel cargada: ${file.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _downloadExcelTemplate() async {
    final bytes = await InstitutionalSettings.instance.getExcelTemplateBytes();
    final location = await getSaveLocation(
      suggestedName: _customExcelName ?? 'plantilla_cmi_impresiones.xlsx',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'XLSX', extensions: ['xlsx']),
      ],
    );
    if (location == null) return;

    final target = File(location.path);
    await target.writeAsBytes(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plantilla descargada en: ${target.path}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetExcelTemplate() async {
    await InstitutionalSettings.instance.resetExcelTemplate();
    if (mounted) {
      setState(() {
        _customExcelName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se restauró la plantilla Excel predeterminada'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando configuración...'),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header macOS
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuración Institucional',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            fontFamily: '-apple-system',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Personaliza firmas oficiales, destinatarios y plantillas para reportes',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontFamily: '-apple-system',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 20, color: textSecondary),
                    splashRadius: 16,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: borderSubtle),

            // Selector de pestaña Segmented
            Container(
              margin: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: surfaceElevated,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _segmentTab(
                      index: 0,
                      title: 'Firmas y Oficio',
                      icon: Icons.edit_note_rounded,
                    ),
                  ),
                  Expanded(
                    child: _segmentTab(
                      index: 1,
                      title: 'Plantillas Word y Excel',
                      icon: Icons.file_present_rounded,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido dinámico
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                child: _selectedTab == 0
                    ? _buildFirmasTab()
                    : _buildPlantillasTab(),
              ),
            ),

            Divider(height: 1, thickness: 1, color: borderSubtle),

            // Footer con botones
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: textSecondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Cancelar',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _saveData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentPetrol,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Guardar Cambios',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentTab({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? surfaceCard : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isVoxelDarkMode ? 0.25 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? accentPetrol : textSecondary,
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? textPrimary : textSecondary,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: '-apple-system',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirmasTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldGroupTitle('DESTINATARIO OFICIAL (DIRECTOR O COORDINADOR)'),
        const SizedBox(height: 8),
        _inputField(
          label: 'A quien se dirige el reporte',
          controller: _directorCtrl,
          hint: 'Ej. JUAN DIONISIO CRUZ GUERRERO',
        ),
        const SizedBox(height: 10),
        _inputField(
          label: 'Cargo institucional',
          controller: _directorRoleCtrl,
          hint: 'Ej. Director del Instituto Tecnológico de Ciudad Madero',
        ),
        const SizedBox(height: 18),

        _fieldGroupTitle('JEFATURA DE DEPARTAMENTO O LABORATORIO'),
        const SizedBox(height: 8),
        _inputField(
          label: 'Nombre del Encargado / Jefe',
          controller: _encargadoCtrl,
          hint: 'Ej. CÉSAR DAVID RIVERA TOSCANO',
        ),
        const SizedBox(height: 10),
        _inputField(
          label: 'Puesto del Encargado',
          controller: _encargadoRoleCtrl,
          hint: 'Ej. ENCARGADO DEL DEPTO. DE ING. INDUSTRIAL',
        ),
        const SizedBox(height: 18),

        _fieldGroupTitle('RESPONSABLE O AUXILIAR QUE ELABORA'),
        const SizedBox(height: 8),
        _inputField(
          label: 'Nombre de quien elabora',
          controller: _remitenteCtrl,
          hint: 'Ej. Néstor Hilario Torres Campa',
        ),
        const SizedBox(height: 10),
        _inputField(
          label: 'Cargo o función',
          controller: _remitenteRoleCtrl,
          hint: 'Ej. Auxiliar administrativo',
        ),
        const SizedBox(height: 18),

        _fieldGroupTitle('DATOS DE CABECERA Y LEMA'),
        const SizedBox(height: 8),
        _inputField(
          label: 'Departamento',
          controller: _departmentCtrl,
          hint: 'Ej. Departamento de Ingeniería Industrial',
        ),
        const SizedBox(height: 10),
        _inputField(
          label: 'Lema del año',
          controller: _lemaCtrl,
          hint: 'Ej. 2026, Año de la Educación Tecnológica',
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildPlantillasTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuando la institución renueve los logos, membretes o formatos de entrega, puedes subir tus archivos Word y Excel aquí. La aplicación los usará automáticamente para rellenar los datos de inventario y consumos.',
          style: TextStyle(
            color: textSecondary,
            fontSize: 12.5,
            height: 1.4,
            fontFamily: '-apple-system',
          ),
        ),
        const SizedBox(height: 16),

        // Tarjeta Word
        _templateCard(
          title: 'Plantilla de Inventario en Word (.docx)',
          subtitle:
              'Contiene membretes institucionales, tablas de material sellado/en uso y espacios de firmas.',
          customName: _customWordName,
          fileExtension: '.docx',
          onUpload: _pickWordTemplate,
          onDownload: _downloadWordTemplate,
          onReset: _customWordName != null ? _resetWordTemplate : null,
        ),

        const SizedBox(height: 14),

        // Tarjeta Excel
        _templateCard(
          title: 'Plantilla de Control de Impresiones en Excel (.xlsx)',
          subtitle:
              'Libro de cálculo oficial CMI con encabezados de departamento y columnas tabulares de piezas.',
          customName: _customExcelName,
          fileExtension: '.xlsx',
          onUpload: _pickExcelTemplate,
          onDownload: _downloadExcelTemplate,
          onReset: _customExcelName != null ? _resetExcelTemplate : null,
        ),
      ],
    );
  }

  Widget _templateCard({
    required String title,
    required String subtitle,
    required String? customName,
    required String fileExtension,
    required VoidCallback onUpload,
    required VoidCallback onDownload,
    required VoidCallback? onReset,
  }) {
    final isCustom = customName != null && customName.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCustom
              ? accentPetrol.withValues(alpha: 0.35)
              : borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: '-apple-system',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCustom
                      ? accentPetrol.withValues(alpha: 0.12)
                      : borderSubtle.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCustom ? 'Personalizada' : 'Predeterminada',
                  style: TextStyle(
                    color: isCustom ? accentPetrol : textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontFamily: '-apple-system',
            ),
          ),
          if (isCustom) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 14, color: accentPetrol),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Archivo activo: $customName',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_file_rounded, size: 15),
                label: Text('Subir $fileExtension'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentPetrol,
                  side: BorderSide(color: accentPetrol.withValues(alpha: 0.4)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded, size: 15),
                label: const Text('Descargar actual'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: BorderSide(color: borderSubtle),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              if (onReset != null)
                TextButton.icon(
                  onPressed: onReset,
                  icon: Icon(Icons.restore_rounded,
                      size: 15, color: textSecondary),
                  label: Text('Restablecer',
                      style: TextStyle(color: textSecondary, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldGroupTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: textSecondary,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        fontFamily: '-apple-system',
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: '-apple-system',
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderSubtle),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: textPrimary,
              fontSize: 13,
              fontFamily: '-apple-system',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: textMuted, fontSize: 12),
              isDense: true,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}
