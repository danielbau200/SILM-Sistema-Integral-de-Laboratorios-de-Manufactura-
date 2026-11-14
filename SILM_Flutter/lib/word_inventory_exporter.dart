import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'institutional_settings.dart';
import 'models.dart';

class WordInventoryReportConfig {
  final DateTime date;
  final String oficioNo;
  final String directorName;
  final String directorRole;
  final String remitenteName;
  final String remitenteRole;
  final String encargadoName;
  final String encargadoRole;
  final String ccp1;
  final String ccp2;

  const WordInventoryReportConfig({
    required this.date,
    this.oficioNo = '',
    this.directorName = 'JUAN DIONISIO CRUZ GUERRERO',
    this.directorRole = 'Director del Instituto Tecnológico de Ciudad Madero',
    this.remitenteName = 'Néstor Hilario Torres Campa',
    this.remitenteRole = 'Auxiliar administrativo',
    this.encargadoName = 'CÉSAR DAVID RIVERA TOSCANO',
    this.encargadoRole = 'ENCARGADO DEL DEPTO. DE ING. INDUSTRIAL',
    this.ccp1 = 'ccp. Archivo',
    this.ccp2 = 'ccp. Subdirección Académica',
  });
}

class WordInventoryExporter {
  static const List<String> spanishMonths = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String _xmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _buildRowXml({
    required int numId,
    required String cantidad,
    required String ubicacion,
    required String descripcion,
  }) {
    return '<w:tr>'
        '<w:trPr><w:trHeight w:val="340"/></w:trPr>'
        '<w:tc>'
        '<w:tcPr><w:tcBorders/><w:tcW w:w="846" w:type="dxa"/></w:tcPr>'
        '<w:p>'
        '<w:pPr>'
        '<w:numPr><w:ilvl w:val="0"/><w:numId w:val="$numId"/></w:numPr>'
        '<w:jc w:val="center"/>'
        '<w:rPr><w:rFonts w:ascii="Noto Sans" w:hAnsi="Noto Sans" w:cs="Noto Sans"/><w:sz w:val="16"/><w:szCs w:val="16"/></w:rPr>'
        '</w:pPr>'
        '<w:r>'
        '<w:rPr><w:rFonts w:ascii="Noto Sans" w:hAnsi="Noto Sans" w:cs="Noto Sans"/><w:sz w:val="16"/><w:szCs w:val="16"/></w:rPr>'
        '</w:r>'
        '</w:p>'
        '</w:tc>'
        '<w:tc>'
        '<w:tcPr><w:tcBorders/><w:tcW w:w="1276" w:type="dxa"/></w:tcPr>'
        '<w:p>'
        '<w:pPr>'
        '<w:jc w:val="center"/>'
        '<w:rPr><w:rFonts w:ascii="Noto Sans" w:hAnsi="Noto Sans" w:cs="Noto Sans"/><w:sz w:val="16"/><w:szCs w:val="16"/></w:rPr>'
        '</w:pPr>'
        '<w:r>'
        '<w:rPr><w:rFonts w:ascii="Noto Sans" w:hAnsi="Noto Sans" w:cs="Noto Sans"/><w:sz w:val="16"/><w:szCs w:val="16"/></w:rPr>'
        '<w:t xml:space="preserve">${_xmlEscape(cantidad)}</w:t>'
        '</w:r>'
        '</w:p>'
        '</w:tc>'
        '<w:tc>'
        '<w:tcPr><w:tcBorders/><w:tcW w:w="2409" w:type="dxa"/></w:tcPr>'
        '<w:p>'
        '<w:pPr>'
        '<w:jc w:val="center"/>'
        '<w:rPr><w:rFonts w:ascii="Noto Sans" w:hAnsi="Noto Sans" w:cs="Noto Sans"/><w:sz w:val="16"/><w:szCs w:val="16"/></w:rPr>'
        '</w:pPr>'
        '<w:r>'
        '<w:rPr><w:rFonts w:ascii="Noto Sans" w:hAnsi="Noto Sans" w:cs="Noto Sans"/><w:sz w:val="16"/><w:szCs w:val="16"/></w:rPr>'
        '<w:t xml:space="preserve">${_xmlEscape(ubicacion)}</w:t>'
        '</w:r>'
        '</w:p>'
        '</w:tc>'
        '<w:tc>'
        '<w:tcPr><w:tcBorders/><w:tcW w:w="5812" w:type="dxa"/></w:tcPr>'
        '<w:p>'
        '<w:pPr>'
        '<w:rPr><w:rFonts w:ascii="Noto Sans" w:hAnsi="Noto Sans" w:cs="Noto Sans"/><w:sz w:val="16"/><w:szCs w:val="16"/></w:rPr>'
        '</w:pPr>'
        '<w:r>'
        '<w:rPr><w:rFonts w:ascii="Noto Sans" w:hAnsi="Noto Sans" w:cs="Noto Sans"/><w:sz w:val="16"/><w:szCs w:val="16"/></w:rPr>'
        '<w:t xml:space="preserve">${_xmlEscape(descripcion)}</w:t>'
        '</w:r>'
        '</w:p>'
        '</w:tc>'
        '</w:tr>';
  }

  static Future<Uint8List> _loadTemplateBytes() async {
    return InstitutionalSettings.instance.getWordTemplateBytes();
  }

  /// Genera los bytes de un documento .docx oficial de inventario de laboratorio
  /// utilizando la plantilla institucional con encabezados, firmas y logos.
  static Future<List<int>> generateDocx({
    required List<InventoryItem> items,
    WordInventoryReportConfig? config,
  }) async {
    await InstitutionalSettings.instance.load();
    final inst = InstitutionalSettings.instance;

    final reportConfig = config ??
        WordInventoryReportConfig(
          date: DateTime.now(),
          directorName: inst.directorName,
          directorRole: inst.directorRole,
          remitenteName: inst.remitenteName,
          remitenteRole: inst.remitenteRole,
          encargadoName: inst.encargadoName,
          encargadoRole: inst.encargadoRole,
          ccp1: inst.ccp1,
          ccp2: inst.ccp2,
        );

    final templateBytes = await _loadTemplateBytes();
    final archive = ZipDecoder().decodeBytes(templateBytes);

    ArchiveFile? docXmlFile;
    for (final f in archive.files) {
      if (f.name == 'word/document.xml') {
        docXmlFile = f;
        break;
      }
    }

    if (docXmlFile == null) {
      throw StateError(
          'Plantilla corrupta: no contiene "word/document.xml".');
    }

    var xml = utf8.decode(docXmlFile.content as List<int>);

    // 1. Fecha oficial
    final monthName = spanishMonths[reportConfig.date.month - 1];
    final dateStr =
        'Ciudad Madero, Tamaulipas, ${reportConfig.date.day}/$monthName/${reportConfig.date.year}';
    xml = xml.replaceFirst(
        RegExp(r'Ciudad Madero, Tamaulipas, [^<]+'), dateStr);

    // 2. Número de Oficio
    final oficioFinal = reportConfig.oficioNo.trim().isNotEmpty
        ? reportConfig.oficioNo.trim()
        : 'OFICIO No.: P. XXXX/${reportConfig.date.year}';
    xml = xml.replaceFirst(
        RegExp(r'OFICIO No\.: [^<]+'), oficioFinal);

    // Reemplazo dinámico de autoridades y firmas oficiales
    if (reportConfig.directorName.isNotEmpty) {
      xml = xml.replaceAll(
          'JUAN DIONISIO CRUZ GUERRERO', _xmlEscape(reportConfig.directorName));
      xml = xml.replaceAll(
          '{{DIRECTOR}}', _xmlEscape(reportConfig.directorName));
    }
    if (reportConfig.directorRole.isNotEmpty) {
      xml = xml.replaceAll(
          '{{DIRECTOR_CARGO}}', _xmlEscape(reportConfig.directorRole));
    }
    if (reportConfig.encargadoName.isNotEmpty) {
      xml = xml.replaceAll(
          'CÉSAR DAVID RIVERA TOSCANO', _xmlEscape(reportConfig.encargadoName));
      xml = xml.replaceAll(
          '{{ENCARGADO}}', _xmlEscape(reportConfig.encargadoName));
    }
    if (reportConfig.encargadoRole.isNotEmpty) {
      xml = xml.replaceAll(
          '{{ENCARGADO_CARGO}}', _xmlEscape(reportConfig.encargadoRole));
    }
    if (reportConfig.remitenteName.isNotEmpty) {
      xml = xml.replaceAll(
          'Néstor Hilario Torres Campa', _xmlEscape(reportConfig.remitenteName));
      xml = xml.replaceAll(
          '{{REMITENTE}}', _xmlEscape(reportConfig.remitenteName));
    }
    if (reportConfig.remitenteRole.isNotEmpty) {
      xml = xml.replaceAll(
          '{{REMITENTE_CARGO}}', _xmlEscape(reportConfig.remitenteRole));
    }

    // 3. Separación de materiales en Sellado y En Uso
    final activeItems = items.where((i) => i.stockActual > 0.001).toList();

    // Material sellado: cerrado, nuevo, stockActual >= stockInicial y no marcado enUso
    final sealedItems = activeItems.where((i) => i.isSellado).toList();

    // Material en uso: abierto, en uso o consumido parcialmente
    final inUseItems = activeItems.where((i) => i.isEnUso).toList();

    // --- TABLA 1: Material Sellado ---
    // Agrupamos carretes idénticos (mismo material, color, marca y ubicación)
    final sealedGroupMap = <String, List<InventoryItem>>{};
    for (final item in sealedItems) {
      final key =
          '${item.material.trim().toUpperCase()}__${item.color.trim().toUpperCase()}__${item.brand.trim().toUpperCase()}__${item.effectiveLocation.toUpperCase()}';
      sealedGroupMap.putIfAbsent(key, () => []).add(item);
    }

    final sealedRowsXml = <String>[];
    if (sealedGroupMap.isEmpty) {
      sealedRowsXml.add(_buildRowXml(
        numId: 14,
        cantidad: '-',
        ubicacion: 'CMI',
        descripcion: 'SIN MATERIAL SELLADO EN INVENTARIO',
      ));
    } else {
      for (final entry in sealedGroupMap.entries) {
        final group = entry.value;
        final sample = group.first;
        final count = group.length;
        final totalGrams = group.fold<double>(0.0, (sum, i) => sum + i.stockActual);

        // Cantidad formateada como en la plantilla:
        // Ej: '5 KG.', '1 KG.', '4 PZAS.'
        String cantidadStr;
        if (sample.stockInicial == 1000 && count >= 1) {
          cantidadStr = '$count KG.';
        } else if (totalGrams >= 1000 && totalGrams % 1000 == 0) {
          cantidadStr = '${(totalGrams / 1000).toInt()} KG.';
        } else if (count == 1 && totalGrams < 1000) {
          cantidadStr = '1 PZA.';
        } else {
          cantidadStr = '$count PZAS.';
        }

        // Descripción: 'PLA BLANCO +', 'PLA SNULU NEGRO', 'PLA ELEGOO AMARILLO', 'PETG VERDE'
        var desc = '${sample.material.toUpperCase()} ${sample.color.toUpperCase()}';
        final brandClean = sample.brand.trim();
        if (brandClean.isNotEmpty &&
            brandClean.toLowerCase() != 'genérica' &&
            brandClean.toLowerCase() != 'generica') {
          desc = '${sample.material.toUpperCase()} ${brandClean.toUpperCase()} ${sample.color.toUpperCase()}';
        }
        if (sample.finish.trim().isNotEmpty &&
            sample.finish.toLowerCase() != 'estándar' &&
            sample.finish.toLowerCase() != 'estandar') {
          desc += ' (${sample.finish.toUpperCase()})';
        }
        if (sample.stockInicial < 1000 && count > 1) {
          desc = '${sample.stockInicial.toInt()} GRAMOS DE FILAMENTO $desc';
        }

        sealedRowsXml.add(_buildRowXml(
          numId: 14,
          cantidad: cantidadStr,
          ubicacion: sample.effectiveLocation,
          descripcion: desc,
        ));
      }
    }

    // --- TABLA 2: Material En Uso ---
    // En la plantilla se listan individualmente:
    // '1 PZA.' | 'CMI' | '200 G DE PLA+ BLANCO'
    // '1 PZA.' | 'CMI' | '500 G DE PLA AMARILLO (MARCA:FUTUR3D)'
    final inUseRowsXml = <String>[];
    if (inUseItems.isEmpty) {
      inUseRowsXml.add(_buildRowXml(
        numId: 12,
        cantidad: '-',
        ubicacion: 'CMI',
        descripcion: 'SIN MATERIAL EN USO ACTUALMENTE',
      ));
    } else {
      for (final item in inUseItems) {
        final g = item.stockActual % 1 == 0
            ? item.stockActual.toInt().toString()
            : item.stockActual.toStringAsFixed(0);
        var desc = '$g G DE ${item.material.toUpperCase()} ${item.color.toUpperCase()}';
        final brandClean = item.brand.trim();
        if (brandClean.isNotEmpty &&
            brandClean.toLowerCase() != 'genérica' &&
            brandClean.toLowerCase() != 'generica') {
          desc += ' (MARCA:${brandClean.toUpperCase()})';
        }
        if (item.finish.trim().isNotEmpty &&
            item.finish.toLowerCase() != 'estándar' &&
            item.finish.toLowerCase() != 'estandar') {
          desc += ' [${item.finish.toUpperCase()}]';
        }

        inUseRowsXml.add(_buildRowXml(
          numId: 12,
          cantidad: '1 PZA.',
          ubicacion: item.effectiveLocation,
          descripcion: desc,
        ));
      }
    }

    // 4. Inserción de filas en las 2 tablas en document.xml
    final tblMatches =
        RegExp(r'<w:tbl(?:[\s\S]*?)<\/w:tbl>').allMatches(xml).toList();
    if (tblMatches.length >= 2) {
      // Tabla 0 (Material sellado)
      final tbl0Xml = tblMatches[0].group(0)!;
      final firstRowMatch0 =
          RegExp(r'<w:tr(?:[\s\S]*?)<\/w:tr>').firstMatch(tbl0Xml)!;
      final header0End = tbl0Xml.indexOf(firstRowMatch0.group(0)!) +
          firstRowMatch0.group(0)!.length;
      final tbl0Prefix = tbl0Xml.substring(0, header0End);
      final newTbl0 = '$tbl0Prefix${sealedRowsXml.join()}</w:tbl>';

      // Tabla 1 (Material en uso)
      final tbl1Xml = tblMatches[1].group(0)!;
      final firstRowMatch1 =
          RegExp(r'<w:tr(?:[\s\S]*?)<\/w:tr>').firstMatch(tbl1Xml)!;
      final header1End = tbl1Xml.indexOf(firstRowMatch1.group(0)!) +
          firstRowMatch1.group(0)!.length;
      final tbl1Prefix = tbl1Xml.substring(0, header1End);
      final newTbl1 = '$tbl1Prefix${inUseRowsXml.join()}</w:tbl>';

      // Reemplazo de atrás hacia adelante para no alterar offsets
      xml = xml.substring(0, tblMatches[1].start) +
          newTbl1 +
          xml.substring(tblMatches[1].end);
      xml = xml.substring(0, tblMatches[0].start) +
          newTbl0 +
          xml.substring(tblMatches[0].end);
    }

    // 5. Re-empaquetar zip docx
    final newArchive = Archive();
    final newDocXmlBytes = utf8.encode(xml);
    for (final f in archive.files) {
      if (f.name == 'word/document.xml') {
        newArchive
            .addFile(ArchiveFile(f.name, newDocXmlBytes.length, newDocXmlBytes));
      } else {
        newArchive.addFile(ArchiveFile(f.name, f.size, f.content));
      }
    }

    final outBytes = ZipEncoder().encode(newArchive);
    if (outBytes == null) {
      throw StateError('Error al codificar el archivo Word .docx.');
    }
    return outBytes;
  }

  /// Genera un documento .docx oficial de Solicitud de Pedido de Materiales e Insumos
  /// utilizando la misma plantilla institucional con encabezados y autoridades oficiales.
  /// Adapta las dos tablas:
  ///   - Tabla 1: Materiales y Filamentos Solicitados
  ///   - Tabla 2: Insumos, Refacciones y Consumibles Solicitados
  static Future<List<int>> generateOrderRequestDocx({
    required List<MaterialOrderReportItem> materialOrders,
    required List<ConsumableOrderReportItem> consumableOrders,
    WordInventoryReportConfig? config,
    String? asuntoCustom,
  }) async {
    await InstitutionalSettings.instance.load();
    final inst = InstitutionalSettings.instance;

    final reportConfig = config ??
        WordInventoryReportConfig(
          date: DateTime.now(),
          directorName: inst.directorName,
          directorRole: inst.directorRole,
          remitenteName: inst.remitenteName,
          remitenteRole: inst.remitenteRole,
          encargadoName: inst.encargadoName,
          encargadoRole: inst.encargadoRole,
          ccp1: inst.ccp1,
          ccp2: inst.ccp2,
        );

    final templateBytes = await _loadTemplateBytes();
    final archive = ZipDecoder().decodeBytes(templateBytes);

    ArchiveFile? docXmlFile;
    for (final f in archive.files) {
      if (f.name == 'word/document.xml') {
        docXmlFile = f;
        break;
      }
    }

    if (docXmlFile == null) {
      throw StateError('Plantilla corrupta: no contiene "word/document.xml".');
    }

    var xml = utf8.decode(docXmlFile.content as List<int>);

    // 1. Fecha oficial
    final monthName = spanishMonths[reportConfig.date.month - 1];
    final dateStr =
        'Ciudad Madero, Tamaulipas, ${reportConfig.date.day}/$monthName/${reportConfig.date.year}';
    xml = xml.replaceFirst(
        RegExp(r'Ciudad Madero, Tamaulipas, [^<]+'), dateStr);

    // 2. Número de Oficio
    final oficioFinal = reportConfig.oficioNo.trim().isNotEmpty
        ? reportConfig.oficioNo.trim()
        : 'OFICIO No.: P. XXXX/${reportConfig.date.year}';
    xml = xml.replaceFirst(
        RegExp(r'OFICIO No\.: [^<]+'), oficioFinal);

    // 3. Asunto oficial
    final asuntoFinal = asuntoCustom ?? 'Solicitud de Materiales e Insumos para Laboratorio 3D';
    xml = xml.replaceFirst('El que se indica', _xmlEscape(asuntoFinal));

    // 4. Firmas y autoridades institucionales
    if (reportConfig.directorName.isNotEmpty) {
      xml = xml.replaceAll(
          'JUAN DIONISIO CRUZ GUERRERO', _xmlEscape(reportConfig.directorName));
      xml = xml.replaceAll(
          '{{DIRECTOR}}', _xmlEscape(reportConfig.directorName));
    }
    if (reportConfig.directorRole.isNotEmpty) {
      xml = xml.replaceAll(
          '{{DIRECTOR_CARGO}}', _xmlEscape(reportConfig.directorRole));
    }
    if (reportConfig.encargadoName.isNotEmpty) {
      xml = xml.replaceAll(
          'CÉSAR DAVID RIVERA TOSCANO', _xmlEscape(reportConfig.encargadoName));
      xml = xml.replaceAll(
          '{{ENCARGADO}}', _xmlEscape(reportConfig.encargadoName));
    }
    if (reportConfig.encargadoRole.isNotEmpty) {
      xml = xml.replaceAll(
          '{{ENCARGADO_CARGO}}', _xmlEscape(reportConfig.encargadoRole));
    }
    if (reportConfig.remitenteName.isNotEmpty) {
      xml = xml.replaceAll(
          'Néstor Hilario Torres Campa', _xmlEscape(reportConfig.remitenteName));
      xml = xml.replaceAll(
          '{{REMITENTE}}', _xmlEscape(reportConfig.remitenteName));
    }
    if (reportConfig.remitenteRole.isNotEmpty) {
      xml = xml.replaceAll(
          '{{REMITENTE_CARGO}}', _xmlEscape(reportConfig.remitenteRole));
    }

    // 5. Renombrar encabezados de sección
    // "Material sellado " -> "Material y Filamentos solicitados"
    // "Material en uso "  -> "Insumos y Consumibles solicitados"
    xml = xml.replaceFirst(
      RegExp(r'<w:p [^>]*>(?:(?!<w:p )[\s\S])*?<w:t[^>]*>Material sellado </w:t>[\s\S]*?</w:p>'),
      '<w:p><w:pPr><w:pStyle w:val="995" /><w:pBdr/><w:spacing w:line="276" w:lineRule="auto" /><w:ind /><w:jc w:val="both" /><w:rPr><w:rFonts w:ascii="Noto Sans" w:hAnsi="Noto Sans" w:cs="Noto Sans" /><w:b/><w:sz w:val="20" /><w:szCs w:val="20" /></w:rPr></w:pPr><w:r><w:rPr><w:rFonts w:ascii="Noto Sans" w:hAnsi="Noto Sans" w:cs="Noto Sans" /><w:b/><w:sz w:val="20" /><w:szCs w:val="20" /></w:rPr><w:t xml:space="preserve">Material y Filamentos solicitados</w:t></w:r></w:p>',
    );

    xml = xml.replaceFirst(
      RegExp(r'<w:p [^>]*>(?:(?!<w:p )[\s\S])*?<w:t[^>]*>Material en uso </w:t>[\s\S]*?</w:p>'),
      '<w:p><w:pPr><w:pStyle w:val="994" /><w:pBdr/><w:spacing w:line="276" w:lineRule="auto" /><w:ind /><w:rPr><w:rFonts w:ascii="Noto Sans" w:hAnsi="Noto Sans" w:cs="Noto Sans" /><w:b/><w:sz w:val="20" /><w:szCs w:val="20" /></w:rPr></w:pPr><w:r><w:rPr><w:rFonts w:ascii="Noto Sans" w:hAnsi="Noto Sans" w:cs="Noto Sans" /><w:b/><w:sz w:val="20" /><w:szCs w:val="20" /></w:rPr><w:t xml:space="preserve">Insumos y Consumibles solicitados</w:t></w:r></w:p>',
    );

    // --- TABLA 1: Filamentos / Carretes Solicitados ---
    final filamentRowsXml = <String>[];
    if (materialOrders.isEmpty) {
      filamentRowsXml.add(_buildRowXml(
        numId: 14,
        cantidad: '-',
        ubicacion: 'CMI',
        descripcion: 'NO SE SOLICITAN CARRETES DE FILAMENTO EN ESTE LOTE',
      ));
    } else {
      for (final order in materialOrders) {
        var cant = '1 PZA.';
        if (order.spoolGrams != null && order.spoolGrams! >= 1000) {
          final kg = order.spoolGrams! / 1000;
          cant = kg == kg.roundToDouble() ? '${kg.toInt()} KG.' : '${kg.toStringAsFixed(1)} KG.';
        } else if (order.spoolGrams != null && order.spoolGrams! > 0) {
          cant = '${order.spoolGrams!.toInt()} G';
        }

        var desc = '${order.material.toUpperCase()} ${order.color.toUpperCase()}';
        if (order.urgency.isNotEmpty) {
          desc += ' [URGENCIA: ${order.urgency.toUpperCase()}]';
        }
        if (order.urgencyDetails.trim().isNotEmpty) {
          desc += ' · ${order.urgencyDetails.trim()}';
        }

        filamentRowsXml.add(_buildRowXml(
          numId: 14,
          cantidad: cant,
          ubicacion: 'CMI',
          descripcion: desc,
        ));
      }
    }

    // --- TABLA 2: Insumos / Consumibles Solicitados ---
    final consumableRowsXml = <String>[];
    if (consumableOrders.isEmpty) {
      consumableRowsXml.add(_buildRowXml(
        numId: 12,
        cantidad: '-',
        ubicacion: 'CMI',
        descripcion: 'NO SE SOLICITAN INSUMOS NI CONSUMIBLES EN ESTE LOTE',
      ));
    } else {
      for (final item in consumableOrders) {
        var cant = item.quantity.trim().isNotEmpty ? item.quantity.trim().toUpperCase() : '1 PZA.';
        if (!cant.contains('KG') && !cant.contains('PZA') && !cant.contains('L') && !cant.contains('G') && RegExp(r'^\d+$').hasMatch(cant)) {
          cant = '$cant PZAS.';
        }

        var desc = item.name.toUpperCase();
        if (item.urgency.isNotEmpty) {
          desc += ' [URGENCIA: ${item.urgency.toUpperCase()}]';
        }
        if (item.urgencyDetails.trim().isNotEmpty) {
          desc += ' · ${item.urgencyDetails.trim()}';
        }

        consumableRowsXml.add(_buildRowXml(
          numId: 12,
          cantidad: cant,
          ubicacion: 'CMI',
          descripcion: desc,
        ));
      }
    }

    // 6. Inserción de filas en las 2 tablas en document.xml
    final tblMatches =
        RegExp(r'<w:tbl(?:[\s\S]*?)<\/w:tbl>').allMatches(xml).toList();
    if (tblMatches.length >= 2) {
      // Tabla 0 (Materiales)
      final tbl0Xml = tblMatches[0].group(0)!;
      final firstRowMatch0 =
          RegExp(r'<w:tr(?:[\s\S]*?)<\/w:tr>').firstMatch(tbl0Xml)!;
      final header0End = tbl0Xml.indexOf(firstRowMatch0.group(0)!) +
          firstRowMatch0.group(0)!.length;
      final tbl0Prefix = tbl0Xml.substring(0, header0End);
      final newTbl0 = '$tbl0Prefix${filamentRowsXml.join()}</w:tbl>';

      // Tabla 1 (Consumibles)
      final tbl1Xml = tblMatches[1].group(0)!;
      final firstRowMatch1 =
          RegExp(r'<w:tr(?:[\s\S]*?)<\/w:tr>').firstMatch(tbl1Xml)!;
      final header1End = tbl1Xml.indexOf(firstRowMatch1.group(0)!) +
          firstRowMatch1.group(0)!.length;
      final tbl1Prefix = tbl1Xml.substring(0, header1End);
      final newTbl1 = '$tbl1Prefix${consumableRowsXml.join()}</w:tbl>';

      // Reemplazo de atrás hacia adelante
      xml = xml.substring(0, tblMatches[1].start) +
          newTbl1 +
          xml.substring(tblMatches[1].end);
      xml = xml.substring(0, tblMatches[0].start) +
          newTbl0 +
          xml.substring(tblMatches[0].end);
    }

    // 7. Re-empaquetar archivo Word .docx
    final newArchive = Archive();
    final newDocXmlBytes = utf8.encode(xml);
    for (final f in archive.files) {
      if (f.name == 'word/document.xml') {
        newArchive
            .addFile(ArchiveFile(f.name, newDocXmlBytes.length, newDocXmlBytes));
      } else {
        newArchive.addFile(ArchiveFile(f.name, f.size, f.content));
      }
    }

    final outBytes = ZipEncoder().encode(newArchive);
    if (outBytes == null) {
      throw StateError('Error al codificar el archivo Word .docx de solicitud.');
    }
    return outBytes;
  }
}

class MaterialOrderReportItem {
  final String material;
  final String color;
  final double? spoolGrams;
  final String urgency;
  final String urgencyDetails;
  final double cost;

  const MaterialOrderReportItem({
    required this.material,
    required this.color,
    this.spoolGrams,
    required this.urgency,
    required this.urgencyDetails,
    required this.cost,
  });
}

class ConsumableOrderReportItem {
  final String name;
  final String quantity;
  final String urgency;
  final String urgencyDetails;
  final double cost;

  const ConsumableOrderReportItem({
    required this.name,
    required this.quantity,
    required this.urgency,
    required this.urgencyDetails,
    required this.cost,
  });
}
