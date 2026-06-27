import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../../core/utils/browser_file_handler.dart';

abstract final class ExpiryExporter {
  ExpiryExporter._();

  static Future<void> exportPdf({
    required Map<String, dynamic>? dashboard,
    required List<Map<String, dynamic>> items,
  }) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (_) => [
          pw.Header(level: 0, child: pw.Text('Relatório de Validades')),
          if (dashboard != null)
            pw.Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _summary('Expirados', '${dashboard['lotesExpirados'] ?? 0}'),
                _summary('30 dias', '${dashboard['expiramEm30Dias'] ?? 0}'),
                _summary('60 dias', '${dashboard['expiramEm60Dias'] ?? 0}'),
                _summary(
                  'Valor em risco',
                  '${dashboard['valorFinanceiroEmRisco'] ?? 0} MZN',
                ),
              ],
            ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Produto',
              'Lote',
              'Validade',
              'Dias',
              'Qtd',
              'Valor',
              'Estado',
            ],
            data: items
                .map(
                  (item) => [
                    item['produtoNome']?.toString() ?? '—',
                    item['numeroLote']?.toString() ?? '—',
                    _date(item['dataValidade']),
                    '${item['diasRestantes'] ?? '—'}',
                    '${item['quantidadeDisponivel'] ?? 0}',
                    '${item['valorEmStock'] ?? 0}',
                    item['estado']?.toString() ?? '—',
                  ],
                )
                .toList(growable: false),
          ),
        ],
      ),
    );

    await BrowserFileHandler.downloadBytes(
      bytes: Uint8List.fromList(await document.save()),
      fileName: 'validades-relatorio.pdf',
      contentType: 'application/pdf',
    );
  }

  static Future<void> exportExcel({
    required List<Map<String, dynamic>> items,
  }) async {
    final buffer = StringBuffer()
      ..writeln('<html><head><meta charset="utf-8"></head><body>')
      ..writeln('<table border="1">')
      ..writeln(
        '<tr><th>Produto</th><th>Lote</th><th>Validade</th><th>Dias</th><th>Quantidade</th><th>Valor</th><th>Estado</th></tr>',
      );

    for (final item in items) {
      buffer.writeln(
        '<tr>'
        '<td>${_escape(item['produtoNome'])}</td>'
        '<td>${_escape(item['numeroLote'])}</td>'
        '<td>${_escape(_date(item['dataValidade']))}</td>'
        '<td>${_escape(item['diasRestantes'])}</td>'
        '<td>${_escape(item['quantidadeDisponivel'])}</td>'
        '<td>${_escape(item['valorEmStock'])}</td>'
        '<td>${_escape(item['estado'])}</td>'
        '</tr>',
      );
    }

    buffer
      ..writeln('</table>')
      ..writeln('</body></html>');

    await BrowserFileHandler.downloadBytes(
      bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
      fileName: 'validades-relatorio.xls',
      contentType: 'application/vnd.ms-excel',
    );
  }

  static pw.Widget _summary(String label, String value) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static String _escape(dynamic value) {
    return (value ?? '—').toString().replaceAll('&', '&amp;').replaceAll('<', '&lt;');
  }

  static String _date(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return '—';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }
}
