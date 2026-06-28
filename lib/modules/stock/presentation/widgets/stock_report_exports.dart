import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/presentation/controllers/report_controller.dart';

Map<String, dynamic> stockReportQuery(Map<String, dynamic> params) {
  final query = <String, dynamic>{};
  params.forEach((key, value) {
    if (value == null) return;
    if (value is String && value.isEmpty) return;
    query[key] = value;
  });
  return query;
}

List<Widget> stockReportActions({
  required WidgetRef ref,
  required bool enabled,
  required String path,
  required Map<String, dynamic> queryParameters,
}) {
  final reportState = ref.watch(reportControllerProvider);
  final reportController = ref.read(reportControllerProvider.notifier);
  final isBusy = !enabled || reportState.isSubmitting;
  final query = stockReportQuery(queryParameters);

  return [
    OutlinedButton.icon(
      onPressed: isBusy
          ? null
          : () => reportController.previewPdf(path: path, queryParameters: query),
      icon: const Icon(Icons.picture_as_pdf_outlined),
      label: const Text('Visualizar PDF'),
    ),
    OutlinedButton.icon(
      onPressed: isBusy
          ? null
          : () => reportController.downloadPdf(path: path, queryParameters: query),
      icon: const Icon(Icons.download_outlined),
      label: const Text('Download PDF'),
    ),
    OutlinedButton.icon(
      onPressed: isBusy
          ? null
          : () => reportController.printPdf(path: path, queryParameters: query),
      icon: const Icon(Icons.print_outlined),
      label: const Text('Imprimir'),
    ),
    OutlinedButton.icon(
      onPressed: isBusy
          ? null
          : () => reportController.exportCsv(path: path, queryParameters: query),
      icon: const Icon(Icons.table_rows_outlined),
      label: const Text('Exportar CSV'),
    ),
    OutlinedButton.icon(
      onPressed: isBusy
          ? null
          : () => reportController.exportExcel(path: path, queryParameters: query),
      icon: const Icon(Icons.table_view_outlined),
      label: const Text('Exportar Excel'),
    ),
  ];
}

Widget? stockReportError(WidgetRef ref) {
  final message = ref.watch(reportControllerProvider).errorMessage;
  if (message == null) return null;
  return Text(message);
}

String formatReportDate(DateTime value) {
  final year = value.year;
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
