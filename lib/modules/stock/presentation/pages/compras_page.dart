import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../providers/compra_provider.dart';

class ComprasPage extends ConsumerWidget {
  const ComprasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(comprasProvider);
    final controller = ref.read(comprasProvider.notifier);
    final t = context.pharmaTokens;

    return EnterpriseModuleHub(
      title: 'Compras',
      subtitle: 'Compras pendentes e recebidas geridas pelo módulo nativo.',
      tag: 'Compras',
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutePaths.stockPurchaseSuggestions),
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Sugestão de Compras'),
        ),
        OutlinedButton.icon(
          onPressed: state.isLoading ? null : controller.load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      child: Column(
        children: [
          if (state.errorMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: context.spacing.sm),
              child: Text(
                state.errorMessage!,
                style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.posDanger),
              ),
            ),
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: state.items.isEmpty && !state.isLoading
                ? const Center(child: Text('Nenhuma compra registada'))
                : EnterpriseDataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('DOCUMENTO')),
                      DataColumn(label: Text('FORNECEDOR')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('ITENS')),
                      DataColumn(label: Text('TOTAL')),
                    ],
                    rowCount: state.items.length,
                    rowBuilder: (context, index) {
                      final item = state.items[index];
                      return DataRow(
                        cells: [
                          DataCell(Text(item.numeroDocumento)),
                          DataCell(Text(item.fornecedorNome)),
                          DataCell(Text(item.status)),
                          DataCell(Text('${item.itemCount}')),
                          DataCell(Text('${item.total}')),
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
