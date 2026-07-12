import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/report_paths.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../pharmacy/products/data/datasources/product_remote_datasource.dart';
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
    final reportBusy = ref.watch(reportControllerProvider).isSubmitting;
    final totalLabel = state.totalCount ?? state.items.length;

    return ResponsiveBuilder(
      builder: (context, constraints) {
        return EnterpriseModuleHub(
          title: 'Sugestão de Compras',
          subtitle:
              'Lista consolidada de produtos para reposição — automáticos e manuais.',
          tag: 'Compras',
          actions: [
            OutlinedButton.icon(
              onPressed: state.isLoading || state.isMutating
                  ? null
                  : () => _showAddProductDialog(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar Produto'),
            ),
            PopupMenuButton<String>(
              tooltip: 'Exportar',
              enabled: !state.isLoading && !reportBusy,
              icon: const Icon(Icons.file_download_outlined),
              onSelected: (format) => _exportReport(ref, format, state),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'print', child: Text('Imprimir')),
                const PopupMenuItem(value: 'pdf', child: Text('Exportar PDF')),
                const PopupMenuItem(value: 'excel', child: Text('Exportar Excel')),
              ],
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
              SizedBox(
                width: 220,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Pesquisar produto',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                  onSubmitted: controller.setSearch,
                  onChanged: (value) {
                    if (value.isEmpty) controller.setSearch('');
                  },
                ),
              ),
              DropdownButton<PurchaseSuggestionOriginFilter>(
                value: state.originFilter,
                items: const [
                  DropdownMenuItem(
                    value: PurchaseSuggestionOriginFilter.todas,
                    child: Text('Todas'),
                  ),
                  DropdownMenuItem(
                    value: PurchaseSuggestionOriginFilter.automatica,
                    child: Text('Automáticas'),
                  ),
                  DropdownMenuItem(
                    value: PurchaseSuggestionOriginFilter.manual,
                    child: Text('Manuais'),
                  ),
                ],
                onChanged: state.isLoading
                    ? null
                    : (value) {
                        if (value != null) controller.setOriginFilter(value);
                      },
              ),
              TextButton.icon(
                onPressed: state.isLoading || state.isMutating || state.items.isEmpty
                    ? null
                    : () => _confirmClear(context, controller),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Limpar lista'),
              ),
              Text(
                '$totalLabel sugestão(ões) · ${state.selectedCount} selecionada(s)',
                style: Theme.of(context)
                    .textTheme
                    .erpBodySecondary
                    .copyWith(color: t.textMuted),
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
                    ? const Center(child: Text('Nenhuma sugestão de compra registada'))
                    : EnterpriseDataTable(
                        showCheckboxColumn: true,
                        onSelectAll: controller.toggleSelectAll,
                        columns: const [
                          DataColumn(label: Text('PRODUTO')),
                          DataColumn(label: Text('ORIGEM')),
                          DataColumn(label: Text('CATEGORIA')),
                          DataColumn(label: Text('FORNECEDOR')),
                          DataColumn(label: Text('STOCK')),
                          DataColumn(label: Text('MÍNIMO')),
                          DataColumn(label: Text('CONSUMO/DIA')),
                          DataColumn(label: Text('QTD. SUGERIDA')),
                          DataColumn(label: Text('QTD. APROVADA')),
                          DataColumn(label: Text('PREÇO')),
                          DataColumn(label: Text('')),
                        ],
                        rowCount: state.items.length,
                        rowBuilder: (context, index) {
                          final item = state.items[index];
                          return DataRow(
                            selected: item.selected,
                            onSelectChanged: (value) =>
                                controller.toggleItem(item.produtoId, value),
                            cells: [
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(item.produtoNome),
                                    if (item.observacao != null &&
                                        item.observacao!.isNotEmpty)
                                      Text(
                                        item.observacao!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .erpBodySecondary
                                            .copyWith(color: t.textMuted),
                                      ),
                                  ],
                                ),
                              ),
                              DataCell(Text(item.origemLabel)),
                              DataCell(Text(item.categoriaNome)),
                              DataCell(Text(item.fornecedorNome)),
                              DataCell(Text(_formatQty(item.estoqueAtual))),
                              DataCell(Text(_formatQty(item.estoqueMinimo))),
                              DataCell(Text(_formatQty(item.consumoMedioDiario))),
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
                              DataCell(
                                IconButton(
                                  tooltip: 'Remover',
                                  onPressed: state.isMutating
                                      ? null
                                      : () => controller.removeSuggestion(item.produtoId),
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                ),
                              ),
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

  static Map<String, dynamic> _reportParams(PurchaseSuggestionsState state) {
    return <String, dynamic>{
      if (state.search.trim().isNotEmpty) 'q': state.search.trim(),
      if (state.originFilter != PurchaseSuggestionOriginFilter.todas)
        'origem': switch (state.originFilter) {
          PurchaseSuggestionOriginFilter.automatica => 'AUTOMATICA',
          PurchaseSuggestionOriginFilter.manual => 'MANUAL',
          PurchaseSuggestionOriginFilter.todas => 'TODAS',
        },
    };
  }

  static Future<void> _exportReport(
    WidgetRef ref,
    String format,
    PurchaseSuggestionsState state,
  ) async {
    final controller = ref.read(reportControllerProvider.notifier);
    final params = _reportParams(state);
    switch (format) {
      case 'print':
        await controller.printPdf(
          path: ReportPaths.stockPurchaseSuggestions,
          queryParameters: params,
        );
      case 'pdf':
        await controller.downloadPdf(
          path: ReportPaths.stockPurchaseSuggestions,
          queryParameters: params,
        );
      case 'excel':
        await controller.exportExcel(
          path: ReportPaths.stockPurchaseSuggestions,
          queryParameters: params,
        );
    }
  }

  static Future<void> _confirmClear(
    BuildContext context,
    PurchaseSuggestionsController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar sugestões'),
        content: const Text(
          'Remover todas as sugestões da lista? Esta acção não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.clearSuggestions();
    }
  }

  static Future<void> _showAddProductDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _AddProductDialog(parentRef: ref),
    );
  }
}

class _AddProductDialog extends ConsumerStatefulWidget {
  const _AddProductDialog({required this.parentRef});

  final WidgetRef parentRef;

  @override
  ConsumerState<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<_AddProductDialog> {
  final _searchController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _obsController = TextEditingController();
  String? _selectedProdutoId;
  String? _selectedProdutoNome;
  bool _isSearching = false;
  List<Map<String, dynamic>> _results = const [];

  @override
  void dispose() {
    _searchController.dispose();
    _qtyController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.length < 2) return;

    setState(() => _isSearching = true);
    try {
      final dataSource = ref.read(productRemoteDataSourceProvider);
      final response = await dataSource.searchProducts(query: query, pageSize: 10);
      setState(() {
        _results = response.items
            .map(
              (p) => <String, dynamic>{
                'id': p.id,
                'nome': p.nomeComercial,
              },
            )
            .toList();
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _submit() async {
    final produtoId = _selectedProdutoId;
    final qty = num.tryParse(_qtyController.text.replaceAll(',', '.'));
    if (produtoId == null || qty == null || qty <= 0) return;

    final controller = widget.parentRef.read(purchaseSuggestionsProvider.notifier);
    await controller.addManualSuggestion(
      produtoId: produtoId,
      quantidadeSugerida: qty,
      observacao: _obsController.text.trim().isEmpty ? null : _obsController.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar produto'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar produto',
                suffixIcon: IconButton(
                  icon: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search_rounded),
                  onPressed: _isSearching ? null : _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            if (_results.isNotEmpty)
              SizedBox(
                height: 140,
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    final id = item['id']?.toString() ?? '';
                    final nome = item['nome']?.toString() ?? '—';
                    final selected = _selectedProdutoId == id;
                    return ListTile(
                      dense: true,
                      selected: selected,
                      title: Text(nome),
                      onTap: () {
                        setState(() {
                          _selectedProdutoId = id;
                          _selectedProdutoNome = nome;
                        });
                      },
                    );
                  },
                ),
              ),
            if (_selectedProdutoNome != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Seleccionado: $_selectedProdutoNome'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _qtyController,
              decoration: const InputDecoration(labelText: 'Quantidade sugerida'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _obsController,
              decoration: const InputDecoration(labelText: 'Observação (opcional)'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selectedProdutoId == null ? null : _submit,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

class _DashboardCards extends StatelessWidget {
  const _DashboardCards({required this.dashboard});

  final PurchaseSuggestionDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final cards = [
      _MetricCard(label: 'Produtos sugeridos', value: '${dashboard.produtosAbaixoMinimo}'),
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
