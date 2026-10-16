import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

class FileExportService {
  static Future<bool> downloadText(
    String name,
    String text,
    String mimeType,
  ) async {
    final location = kIsWeb ? null : await getSaveLocation(suggestedName: name);
    if (!kIsWeb && location == null) return false;
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(text)),
      mimeType: mimeType,
      name: name,
    );
    await file.saveTo(location?.path ?? name);
    return true;
  }

  /// Exporta conteúdo de relatório como arquivo CSV formatado com encoding UTF-8
  static String generateCsvReport(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return 'id,studentName,amount,status\n';

    final headers = records.first.keys.toList();
    final buffer = StringBuffer();

    // Adicionar UTF-8 BOM para garantir acentuação correta no Excel / Web
    buffer.write('\uFEFF');
    buffer.writeln(headers.map((h) => _escapeCsvCell(h)).join(','));

    for (var row in records) {
      final line = headers
          .map((h) {
            final val = row[h];
            return _escapeCsvCell(val?.toString() ?? '');
          })
          .join(',');
      buffer.writeln(line);
    }

    return buffer.toString();
  }

  /// Escapa células CSV contendo vírgulas, aspas ou quebras de linha
  static String _escapeCsvCell(String input) {
    if (input.contains(',') || input.contains('"') || input.contains('\n')) {
      final escaped = input.replaceAll('"', '""');
      return '"$escaped"';
    }
    return input;
  }

  /// Exporta conteúdo como JSON formatado
  static String generateJsonReport(dynamic data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}
