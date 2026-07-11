import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../providers/purchase_suggestions_provider.dart';

class PurchaseSuggestionsPage extends ConsumerWidget {
  const PurchaseSuggestionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.spacing;
    final t = context.pharmaTokens;
    final state = ref.watch(purchaseSuggestionsProvider);
    final controller = ref.read(purchaseSuggestionsProvider.notifier);
    final totalLabel = state.totalCount ?? state.items.length;

    return ResponsiveBuilder(
      builder: (context, constraints) {
        return EnterpriseModuleHub(
          title: 'Sugestão de Compras',
          subtitle: 'Lotes com movimentação abaixo do stock mínimo — stock calculado como no módulo Estoque.',
          tag: 'Compras',
          actions: [
            OutlinedButton.icon(
              onPressed: state.isLoading ? null : controller.load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Atualizar'),
            ),
            FilledButton.icon(
              onPressed: state.isLoading || state.isCreating || state.selectedCount == 0
                  ? null
                  : controller.createPurchases,
              icon: state.isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.shopping_cart_checkout_outlined),
              label: const Text('Criar Compra'),
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
                '$totalLabel sugestão(ões) · ${state.selectedCount} selecionada(s)',
                style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
              ),
            ],
          ),
          child: Column(
            children: [
              _DashboardCards(dashboard: state.dashboard),
              if (state.errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: s.sm),
                  child: Text(
                    state.errorMessage!,
                    style: Theme.of(context)
                        .textTheme
                        .erpBodySecondary
                        .copyWith(color: t.posDanger),
                  ),
                ),
              if (state.successMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: s.sm),
                  child: Text(
                    state.successMessage!,
                    style: Theme.of(context)
                        .textTheme
                        .erpBodySecondary
                        .copyWith(color: t.posSuccess),
                  ),
                ),
              if (state.isLoading) const LinearProgressIndicator(),
              Expanded(
                child: state.items.isEmpty && !state.isLoading
                    ? const Center(child: Text('Nenhum produto abaixo do stock mínimo'))
                    : EnterpriseDataTable(
                        showCheckboxColumn: true,
                        onSelectAll: controller.toggleSelectAll,
                        columns: [
                          const DataColumn(label: Text('PRODUTO')),
                          const DataColumn(label: Text('CATEGORIA')),
                          const DataColumn(label: Text('FORNECEDOR')),
                          const DataColumn(label: Text('STOCK')),
                          const DataColumn(label: Text('MÍNIMO')),
                          const DataColumn(label: Text('COBERTURA')),
                          const DataColumn(label: Text('QTD. SUGERIDA')),
                          const DataColumn(label: Text('QTD. APROVADA')),
                          const DataColumn(label: Text('PREÇO')),
                          const DataColumn(label: Text('VALOR')),
                        ],
                        rowCount: state.items.length,
                        rowBuilder: (context, index) {
                          final item = state.items[index];
                          return DataRow(
                            selected: item.selected,
                            onSelectChanged: (value) =>
                                controller.toggleItem(item.produtoId, value),
                            cells: [
                              DataCell(Text(item.produtoNome)),
                              DataCell(Text(item.categoriaNome)),
                              DataCell(Text(item.fornecedorNome)),
                              DataCell(Text(_formatQty(item.estoqueAtual))),
                              DataCell(Text(_formatQty(item.estoqueMinimo))),
                              DataCell(Text('${item.coberturaDias}d')),
                              DataCell(Text(_formatQty(item.quantidadeSugerida))),
                              DataCell(
                                SizedBox(
                                  width: 88,
                                  child: TextFormField(
                                    key: ValueKey(
                                      '${item.produtoId}-${item.quantidadeSugerida}',
                                    ),
                                    initialValue: '${item.quantidadeAprovada}',
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: (value) => controller.updateQuantidadeAprovada(
                                      item.produtoId,
                                      value,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(item.ultimoPreco.toString())),
                              DataCell(Text(item.subtotalAprovado.toStringAsFixed(2))),
                            ],
                          );
                        },
                      ),
              ),
              if (constraints.isTabletOrWider && (state.totalCount ?? 0) > 0)
                EnterprisePagination(
                  page: state.page,
                  pageSize: state.pageSize,
                  totalCount: state.totalCount,
                  hasMore: state.hasMore,
                  itemsOnPage: state.items.length,
                  itemLabel: 'sugestões',
                  onPageChanged: controller.goToPage,
                  onPageSizeChanged: controller.setPageSize,
                  isBusy: state.isLoading,
                ),
            ],
          ),
        );
      },
    );
  }

  static String _formatQty(num value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}

class _DashboardCards extends StatelessWidget {
  const _DashboardCards({required this.dashboard});

  final PurchaseSuggestionDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final cards = [
      _MetricCard(label: 'Abaixo do mínimo', value: '${dashboard.produtosAbaixoMinimo}'),
      _MetricCard(label: 'Sem stock', value: '${dashboard.produtosSemStock}'),
      _MetricCard(label: 'Qtd. total sugerida', value: '${dashboard.quantidadeTotalSugerida}'),
      _MetricCard(label: 'Fornecedores', value: '${dashboard.fornecedoresEnvolvidos}'),
      _MetricCard(label: 'Valor estimado', value: '${dashboard.valorEstimadoCompra} MZN'),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: s.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width > 1100 ? 5 : width > 700 ? 3 : 2;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: s.sm,
            crossAxisSpacing: s.sm,
            childAspectRatio: 2.8,
            children: cards,
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
