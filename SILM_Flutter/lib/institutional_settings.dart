import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InstitutionalSettings {
  static const String _keyDirectorName = 'inst_director_name';
  static const String _keyDirectorRole = 'inst_director_role';
  static const String _keyRemitenteName = 'inst_remitente_name';
  static const String _keyRemitenteRole = 'inst_remitente_role';
  static const String _keyEncargadoName = 'inst_encargado_name';
  static const String _keyEncargadoRole = 'inst_encargado_role';
  static const String _keyDepartment = 'inst_department';
  static const String _keyLema = 'inst_lema';
  static const String _keyCcp1 = 'inst_ccp1';
  static const String _keyCcp2 = 'inst_ccp2';
  static const String _keyCustomWordPath = 'inst_custom_word_path';
  static const String _keyCustomWordName = 'inst_custom_word_name';
  static const String _keyCustomExcelPath = 'inst_custom_excel_path';
  static const String _keyCustomExcelName = 'inst_custom_excel_name';

  // Valores por defecto institucionales
  static const String defaultDirectorName = 'JUAN DIONISIO CRUZ GUERRERO';
  static const String defaultDirectorRole =
      'Director del Instituto Tecnológico de Ciudad Madero';
  static const String defaultRemitenteName = 'Néstor Hilario Torres Campa';
  static const String defaultRemitenteRole = 'Auxiliar administrativo';
  static const String defaultEncargadoName = 'CÉSAR DAVID RIVERA TOSCANO';
  static const String defaultEncargadoRole =
      'ENCARGADO DEL DEPTO. DE ING. INDUSTRIAL';
  static const String defaultDepartment =
      'Departamento de Ingeniería Industrial';
  static const String defaultLema = '2026, Año de la Educación Tecnológica';
  static const String defaultCcp1 = 'ccp. Archivo';
  static const String defaultCcp2 = 'ccp. Subdirección Académica';

  String directorName = defaultDirectorName;
  String directorRole = defaultDirectorRole;
  String remitenteName = defaultRemitenteName;
  String remitenteRole = defaultRemitenteRole;
  String encargadoName = defaultEncargadoName;
  String encargadoRole = defaultEncargadoRole;
  String department = defaultDepartment;
  String lema = defaultLema;
  String ccp1 = defaultCcp1;
  String ccp2 = defaultCcp2;

  String? customWordPath;
  String? customWordName;
  String? customExcelPath;
  String? customExcelName;

  static final InstitutionalSettings instance = InstitutionalSettings._internal();

  InstitutionalSettings._internal();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    directorName = prefs.getString(_keyDirectorName) ?? defaultDirectorName;
    directorRole = prefs.getString(_keyDirectorRole) ?? defaultDirectorRole;
    remitenteName = prefs.getString(_keyRemitenteName) ?? defaultRemitenteName;
    remitenteRole = prefs.getString(_keyRemitenteRole) ?? defaultRemitenteRole;
    encargadoName = prefs.getString(_keyEncargadoName) ?? defaultEncargadoName;
    encargadoRole = prefs.getString(_keyEncargadoRole) ?? defaultEncargadoRole;
    department = prefs.getString(_keyDepartment) ?? defaultDepartment;
    lema = prefs.getString(_keyLema) ?? defaultLema;
    ccp1 = prefs.getString(_keyCcp1) ?? defaultCcp1;
    ccp2 = prefs.getString(_keyCcp2) ?? defaultCcp2;

    customWordPath = prefs.getString(_keyCustomWordPath);
    customWordName = prefs.getString(_keyCustomWordName);
    customExcelPath = prefs.getString(_keyCustomExcelPath);
    customExcelName = prefs.getString(_keyCustomExcelName);

    // Si los archivos personalizados ya no existen en disco, limpiar referencia
    if (customWordPath != null && !File(customWordPath!).existsSync()) {
      customWordPath = null;
      customWordName = null;
      await prefs.remove(_keyCustomWordPath);
      await prefs.remove(_keyCustomWordName);
    }
    if (customExcelPath != null && !File(customExcelPath!).existsSync()) {
      customExcelPath = null;
      customExcelName = null;
      await prefs.remove(_keyCustomExcelPath);
      await prefs.remove(_keyCustomExcelName);
    }
  }

  Future<void> save({
    required String directorName,
    required String directorRole,
    required String remitenteName,
    required String remitenteRole,
    required String encargadoName,
    required String encargadoRole,
    required String department,
    required String lema,
    required String ccp1,
    required String ccp2,
  }) async {
    this.directorName = directorName.trim();
    this.directorRole = directorRole.trim();
    this.remitenteName = remitenteName.trim();
    this.remitenteRole = remitenteRole.trim();
    this.encargadoName = encargadoName.trim();
    this.encargadoRole = encargadoRole.trim();
    this.department = department.trim();
    this.lema = lema.trim();
    this.ccp1 = ccp1.trim();
    this.ccp2 = ccp2.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDirectorName, this.directorName);
    await prefs.setString(_keyDirectorRole, this.directorRole);
    await prefs.setString(_keyRemitenteName, this.remitenteName);
    await prefs.setString(_keyRemitenteRole, this.remitenteRole);
    await prefs.setString(_keyEncargadoName, this.encargadoName);
    await prefs.setString(_keyEncargadoRole, this.encargadoRole);
    await prefs.setString(_keyDepartment, this.department);
    await prefs.setString(_keyLema, this.lema);
    await prefs.setString(_keyCcp1, this.ccp1);
    await prefs.setString(_keyCcp2, this.ccp2);
  }

  Directory _getTemplatesDirectory() {
    final home = Platform.environment['HOME'] ?? '.';
    final dir = Directory('$home/.silm_templates');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<void> setCustomWordTemplate(Uint8List bytes, String fileName) async {
    final dir = _getTemplatesDirectory();
    final target = File('${dir.path}/custom_template_$fileName');
    await target.writeAsBytes(bytes);

    customWordPath = target.path;
    customWordName = fileName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomWordPath, customWordPath!);
    await prefs.setString(_keyCustomWordName, customWordName!);
  }

  Future<void> resetWordTemplate() async {
    if (customWordPath != null) {
      final f = File(customWordPath!);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
    customWordPath = null;
    customWordName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCustomWordPath);
    await prefs.remove(_keyCustomWordName);
  }

  Future<void> setCustomExcelTemplate(Uint8List bytes, String fileName) async {
    final dir = _getTemplatesDirectory();
    final target = File('${dir.path}/custom_template_$fileName');
    await target.writeAsBytes(bytes);

    customExcelPath = target.path;
    customExcelName = fileName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomExcelPath, customExcelPath!);
    await prefs.setString(_keyCustomExcelName, customExcelName!);
  }

  Future<void> resetExcelTemplate() async {
    if (customExcelPath != null) {
      final f = File(customExcelPath!);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
    customExcelPath = null;
    customExcelName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCustomExcelPath);
    await prefs.remove(_keyCustomExcelName);
  }

  Future<Uint8List> getWordTemplateBytes() async {
    if (customWordPath != null) {
      final f = File(customWordPath!);
      if (f.existsSync()) {
        return f.readAsBytesSync();
      }
    }
    // Fallback a plantilla por defecto
    try {
      final data = await rootBundle.load('assets/inventario_template.docx');
      return data.buffer.asUint8List();
    } catch (_) {
      final data =
          await rootBundle.load('assets/templates/inventario_template.docx');
      return data.buffer.asUint8List();
    }
  }

  Future<Uint8List> getExcelTemplateBytes() async {
    if (customExcelPath != null) {
      final f = File(customExcelPath!);
      if (f.existsSync()) {
        return f.readAsBytesSync();
      }
    }
    final data = await rootBundle.load('assets/cmi_template.xlsx');
    return data.buffer.asUint8List();
  }
}
