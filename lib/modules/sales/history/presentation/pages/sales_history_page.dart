import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/utils/list_csv_exporter.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../../invoices/domain/entities/invoice_summary.dart';
import '../../../invoices/presentation/providers/invoice_detail_provider.dart';
import '../../../invoices/presentation/widgets/invoice_detail_screen.dart';
import '../../../invoices/presentation/widgets/invoice_status_badge.dart';
import '../../domain/entities/sales_history.dart';
import '../providers/sales_history_provider.dart';

class SalesHistoryPage extends ConsumerStatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  ConsumerState<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends ConsumerState<SalesHistoryPage> {
  late final TextEditingController _searchController;
  static final _currency = NumberFormat('#,##0.00', 'pt_MZ');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(salesHistoryProvider).query.search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final state = ref.watch(salesHistoryProvider);
    final notifier = ref.read(salesHistoryProvider.notifier);
    final dash = state.dashboard;

    if (_searchController.text != state.query.search) {
      _searchController.value = TextEditingValue(
        text: state.query.search,
        selection: TextSelection.collapsed(offset: state.query.search.length),
      );
    }

    return EnterpriseModuleHub(
      title: 'Histórico de vendas',
      subtitle: 'Drill-down por terminal, operador e linha de receita.',
      tag: 'Terminal',
      actions: [
        OutlinedButton.icon(
          onPressed: state.items.isEmpty ? null : () => _exportHistory(state),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Exportar CSV'),
        ),
        OutlinedButton.icon(
          onPressed: state.isBusy ? null : notifier.refresh,
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
            width: 280,
            child: TextField(
              controller: _searchController,
              onChanged: notifier.onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Nº fatura, cliente ou terminal...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          for (final filter in SalesHistoryQuickFilter.values.where(
            (f) => f != SalesHistoryQuickFilter.none,
          ))
            FilterChip(
              label: Text(_quickFilterLabel(filter)),
              selected: state.query.quickFilter == filter,
              onSelected: state.isBusy
                  ? null
                  : (_) => notifier.setQuickFilter(filter),
            ),
          if (state.query.hasFilters)
            TextButton.icon(
              onPressed: state.isBusy ? null : notifier.clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpar'),
            ),
        ],
      ),
      kpis: [
        EnterpriseStatCard(
          title: 'Vendas',
          value: '${dash.totalVendas}',
          subtitle: 'No período filtrado',
          icon: Icons.point_of_sale_outlined,
          accent: StatCardAccent.info,
        ),
        EnterpriseStatCard(
          title: 'Receita',
          value: '${_currency.format(dash.receitaTotal)} MT',
          icon: Icons.payments_outlined,
          accent: StatCardAccent.positive,
        ),
        EnterpriseStatCard(
          title: 'Ticket médio',
          value: '${_currency.format(dash.ticketMedio)} MT',
          icon: Icons.receipt_long_outlined,
          accent: StatCardAccent.neutral,
        ),
        EnterpriseStatCard(
          title: 'Pagas',
          value: '${state.summary.paid}',
          subtitle: 'Lista actual',
          icon: Icons.check_circle_outline,
          accent: StatCardAccent.positive,
        ),
      ],
      child: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SalesHistoryState state,
    SalesHistoryController notifier,
  ) {
    if (state.viewState == SalesHistoryViewState.loading) {
      return const ModuleLoadingState();
    }
    if (state.viewState == SalesHistoryViewState.error) {
      return ModuleErrorState(
        title: 'Falha ao carregar histórico',
        message: state.errorMessage ?? 'Erro desconhecido',
        onRetry: notifier.refresh,
        icon: Icons.history,
      );
    }
    if (state.viewState == SalesHistoryViewState.empty) {
      return ModuleEmptyState(
        title: 'Nenhuma venda encontrada',
        subtitle: state.query.hasFilters
            ? 'Tenta limpar os filtros para ver mais resultados.'
            : 'Ainda não existem vendas registadas.',
        onClearFilters: state.query.hasFilters ? notifier.clearFilters : null,
      );
    }

    final t = context.pharmaTokens;
    final s = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dashHasTopProducts(state))
          Padding(
            padding: EdgeInsets.only(bottom: s.md),
            child: Wrap(
              spacing: s.sm,
              children: [
                for (final p in state.dashboard.topProdutos.take(3))
                  Chip(
                    avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                    label: Text('${p.nome}: ${_currency.format(p.receita)} MT'),
                  ),
              ],
            ),
          ),
        Expanded(
          child: EnterpriseDataTable(
            columns: [
              for (final label in [
                'Fatura',
                'Cliente',
                'Terminal',
                'Total',
                'Estado',
                'Data',
              ])
                DataColumn(
                  label: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: t.textMuted,
                    ),
                  ),
                ),
            ],
            rowCount: state.items.length,
            rowBuilder: (context, index) {
              final inv = state.items[index];
              return DataRow(
                onSelectChanged: (_) => _openInvoiceDetail(inv),
                cells: [
                  DataCell(
                    Text(
                      inv.numero,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      inv.cliente?.nome ?? '—',
                      style: TextStyle(color: t.textSecondary),
                    ),
                  ),
                  DataCell(
                    Text(
                      inv.terminal?.codigo ?? inv.terminal?.nome ?? '—',
                      style: TextStyle(color: t.textMuted),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${_currency.format(inv.total)} MT',
                      style: TextStyle(
                        color: t.brandGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  DataCell(InvoiceStatusBadge(status: inv.estado)),
                  DataCell(
                    Text(
                      _dateTime.format(inv.createdAt),
                      style: TextStyle(color: t.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: s.md),
        MovimentacoesPagination(
          page: state.query.page,
          pageSize: state.query.pageSize,
          hasMore: state.hasMore,
          isBusy: state.isBusy,
          onPrev: state.query.page > 1
              ? () => notifier.goToPage(state.query.page - 1)
              : null,
          onNext: state.hasMore
              ? () => notifier.goToPage(state.query.page + 1)
              : null,
          onPageSizeChanged: notifier.setPageSize,
        ),
      ],
    );
  }

  bool dashHasTopProducts(SalesHistoryState state) =>
      state.dashboard.topProdutos.isNotEmpty;

  String _quickFilterLabel(SalesHistoryQuickFilter filter) => switch (filter) {
    SalesHistoryQuickFilter.today => 'Hoje',
    SalesHistoryQuickFilter.week => 'Semana',
    SalesHistoryQuickFilter.month => 'Mês',
    SalesHistoryQuickFilter.none => 'Todas',
  };

  Future<void> _openInvoiceDetail(InvoiceSummary invoice) async {
    ref.read(invoiceDetailProvider.notifier).open(invoice);
    final isMobile = PharmaScreenLayout.isMobile(context);

    if (isMobile) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(invoice: invoice),
        ),
      );
      ref.read(invoiceDetailProvider.notifier).close();
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final t = context.pharmaTokens;
        final s = context.spacing;
        return Dialog(
          alignment: Alignment.centerRight,
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: s.md),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 520,
            decoration: BoxDecoration(
              color: t.bgPrimary,
              borderRadius: BorderRadius.circular(t.radiusXl),
              border: Border.all(color: t.border.withValues(alpha: 0.55)),
            ),
            child: InvoiceDetailPanel(
              invoice: invoice,
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );
    ref.read(invoiceDetailProvider.notifier).close();
  }

  Future<void> _exportHistory(SalesHistoryState state) async {
    await ListCsvExporter.export(
      fileName: 'historico-vendas-pagina-${state.query.page}',
      headers: const [
        'Fatura',
        'Cliente',
        'Terminal',
        'Total',
        'Estado',
        'Data',
      ],
      rows: state.items
          .map(
            (inv) => [
              inv.numero,
              inv.cliente?.nome ?? '—',
              inv.terminal?.codigo ?? inv.terminal?.nome ?? '—',
              _currency.format(inv.total),
              inv.estado,
              _dateTime.format(inv.createdAt),
            ],
          )
          .toList(),
    );
  }
}
