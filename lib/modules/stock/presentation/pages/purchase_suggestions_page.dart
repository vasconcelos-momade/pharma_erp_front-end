import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/report_paths.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../providers/purchase_suggestions_provider.dart';

class PurchaseSuggestionsPage extends ConsumerWidget {
  const PurchaseSuggestionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.spacing;
    final t = context.pharmaTokens;
    final state = ref.watch(purchaseSuggestionsProvider);
    final controller = ref.read(purchaseSuggestionsProvider.notifier);
    final reportController = ref.read(reportControllerProvider.notifier);
    final reportState = ref.watch(reportControllerProvider);

    return EnterpriseModuleHub(
      title: 'Sugestão de Compras',
      subtitle: 'Lista gerada pelo backend com base em consumo, stock e mínimos.',
      tag: 'Stock',
      actions: [
        PopupMenuButton<String>(
          enabled: !state.isLoading && !reportState.isSubmitting,
          onSelected: (value) {
            if (value == 'pdf') {
              reportController.downloadPdf(
                path: ReportPaths.stockRequisitionsCompra,
                queryParameters: <String, dynamic>{'days': state.days},
              );
            } else {
              reportController.printPdf(
                path: ReportPaths.stockRequisitionsCompra,
                queryParameters: <String, dynamic>{'days': state.days},
              );
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'pdf', child: Text('Exportar PDF')),
            PopupMenuItem(value: 'print', child: Text('Imprimir')),
          ],
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Exportar'),
          ),
        ),
        OutlinedButton.icon(
          onPressed: state.isLoading ? null : controller.load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      filters: Wrap(
        spacing: s.sm,
        runSpacing: s.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<int>(
            value: state.days,
            items: const [
              DropdownMenuItem(value: 7, child: Text('Últimos 7 dias')),
              DropdownMenuItem(value: 30, child: Text('Últimos 30 dias')),
              DropdownMenuItem(value: 60, child: Text('Últimos 60 dias')),
              DropdownMenuItem(value: 90, child: Text('Últimos 90 dias')),
            ],
            onChanged: state.isLoading
                ? null
                : (value) {
                    if (value != null) controller.setDays(value);
                  },
          ),
          Text(
            '${state.items.length} sugestão(ões)',
            style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
          ),
        ],
      ),
      child: Column(
        children: [
          if (state.errorMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: s.sm),
              child: Text(
                state.errorMessage!,
                style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.posDanger),
              ),
            ),
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: state.items.isEmpty && !state.isLoading
                ? const Center(child: Text('Nenhuma sugestão de compra no período'))
                : EnterpriseDataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('PRODUTO')),
                      DataColumn(label: Text('FORNECEDOR')),
                      DataColumn(label: Text('CONSUMO')),
                      DataColumn(label: Text('ESTOQUE ATUAL')),
                      DataColumn(label: Text('ESTOQUE MÍNIMO')),
                      DataColumn(label: Text('QTD. SUGERIDA')),
                      DataColumn(label: Text('UNIDADE')),
                    ],
                    rowCount: state.items.length,
                    rowBuilder: (context, index) {
                      final item = state.items[index];
                      return DataRow(
                        cells: [
                          DataCell(Text(item.produtoNome)),
                          DataCell(Text(item.fornecedorNome)),
                          DataCell(Text('${item.consumo}')),
                          DataCell(Text('${item.estoqueAtual}')),
                          DataCell(Text('${item.estoqueMinimo}')),
                          DataCell(Text('${item.quantidadeSugerida}')),
                          DataCell(Text(item.unidade)),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
