import 'dart:convert';
import 'dart:typed_data';

import 'browser_file_handler.dart';

abstract final class ListCsvExporter {
  ListCsvExporter._();

  static Future<void> export({
    required String fileName,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final buffer = StringBuffer()
      ..writeln(headers.map(_escape).join(';'));

    for (final row in rows) {
      buffer.writeln(row.map(_escape).join(';'));
    }

    await BrowserFileHandler.downloadBytes(
      bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
      fileName: fileName.endsWith('.csv') ? fileName : '$fileName.csv',
      contentType: 'text/csv;charset=utf-8',
    );
  }

  static String _escape(String value) {
    final normalized = value.replaceAll('\n', ' ').replaceAll('\r', '');
    if (normalized.contains(';') ||
        normalized.contains('"') ||
        normalized.contains(',')) {
      return '"${normalized.replaceAll('"', '""')}"';
    }
    return normalized;
  }
}
