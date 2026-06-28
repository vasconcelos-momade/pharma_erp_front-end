import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/report_paths.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/dashboard_query.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_period_filters.dart';
import '../widgets/dashboard_widgets.dart';

class FinanceDashboardPage extends ConsumerStatefulWidget {
  const FinanceDashboardPage({super.key});

  @override
  ConsumerState<FinanceDashboardPage> createState() =>
      _FinanceDashboardPageState();
}

class _FinanceDashboardPageState extends ConsumerState<FinanceDashboardPage> {
  var _query = const DashboardQuery();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(financeDashboardProvider(_query));
    final reportState = ref.watch(reportControllerProvider);
    final dataSource = ref.watch(dashboardRemoteDataSourceProvider);
    final kpis = dashMap(async.valueOrNull?['kpis']);
    final tables = dashMap(async.valueOrNull?['tables']);
    final charts = dashMap(async.valueOrNull?['charts']);
    final statusOptions = dashboardUniqueOptions(
      dashList(tables?['ultimosPagamentos']).map((row) => row['status']),
    );
    final paymentMethodOptions = dashboardUniqueOptions([
      ...dashList(charts?['metodosPagamento']).map((row) => row['metodo']),
      ...dashList(tables?['ultimosPagamentos']).map((row) => row['metodo']),
    ]);

    Future<void> exportDashboard({String format = 'csv'}) async {
      if (async.valueOrNull == null || reportState.isSubmitting) return;
      await dashboardReportExport(
        ref: ref,
        path: ReportPaths.dashboardFinance,
        query: _query,
        format: format,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exportação do painel financeiro concluída.'),
        ),
      );
    }

    return EnterpriseModuleHub(
      title: 'Painel financeiro',
      subtitle: 'Receitas, despesas, caixa e contas a receber/pagar.',
      tag: 'Dashboard',
      scrollable: true,
      actions: [
        OutlinedButton.icon(
          onPressed: async.valueOrNull == null || reportState.isSubmitting
              ? null
              : () => exportDashboard(format: 'csv'),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Exportar CSV'),
        ),
        OutlinedButton.icon(
          onPressed: async.valueOrNull == null || reportState.isSubmitting
              ? null
              : () => exportDashboard(format: 'excel'),
          icon: const Icon(Icons.table_view_outlined),
          label: const Text('Exportar Excel'),
        ),
        OutlinedButton.icon(
          onPressed: async.valueOrNull == null || reportState.isSubmitting
              ? null
              : () => exportDashboard(format: 'pdf'),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Exportar PDF'),
        ),
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(financeDashboardProvider(_query)),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      filters: DashboardPeriodFilters(
        query: _query,
        onChanged: (query) => setState(() => _query = query),
        statusOptions: statusOptions,
        paymentMethodOptions: paymentMethodOptions,
      ),
      kpis: kpis == null
          ? null
          : [
              dashboardKpiCard(
                title: 'Receita',
                value: '${dashKpi(kpis, 'receita')} MZN',
                icon: Icons.trending_up,
                accent: StatCardAccent.positive,
              ),
              dashboardKpiCard(
                title: 'Despesas',
                value: '${dashKpi(kpis, 'despesas')} MZN',
                icon: Icons.trending_down,
                accent: StatCardAccent.warning,
              ),
              dashboardKpiCard(
                title: 'Lucro',
                value: '${dashKpi(kpis, 'lucro')} MZN',
                icon: Icons.percent,
                accent: StatCardAccent.info,
              ),
              dashboardKpiCard(
                title: 'Fluxo caixa',
                value: '${dashKpi(kpis, 'fluxoCaixa')} MZN',
                icon: Icons.swap_horiz_outlined,
                accent: StatCardAccent.info,
              ),
              dashboardKpiCard(
                title: 'Saldo caixa',
                value: '${dashKpi(kpis, 'saldoAtual')} MZN',
                icon: Icons.account_balance_wallet,
                accent: StatCardAccent.positive,
              ),
              dashboardKpiCard(
                title: 'A receber',
                value: '${dashKpi(kpis, 'contasReceber')} MZN',
                icon: Icons.call_received,
              ),
              dashboardKpiCard(
                title: 'A pagar',
                value: '${dashKpi(kpis, 'contasPagar')} MZN',
                icon: Icons.call_made,
              ),
              dashboardKpiCard(
                title: 'Receb. pendentes',
                value: dashKpi(kpis, 'recebimentosPendentes'),
                icon: Icons.pending_actions,
              ),
              dashboardKpiCard(
                title: 'Pag. pendentes',
                value: dashKpi(kpis, 'pagamentosPendentes'),
                icon: Icons.pending_outlined,
              ),
            ],
      child: dashboardAsyncBody(
        async: async,
        onRetry: () => ref.invalidate(financeDashboardProvider(_query)),
        builder: (data) {
          final charts = dashMap(data['charts']);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final chartWidth = constraints.maxWidth >= 1100
                      ? (constraints.maxWidth - AppSpacing.lg) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
                    children: [
                      SizedBox(
                        width: chartWidth,
                        child: dashboardChartCard(
                          context: context,
                          title: 'Receitas x despesas',
                          child: dashboardDualLineChart(
                            context: context,
                            points: dashList(charts?['receitasDespesas']),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: dashboardChartCard(
                          context: context,
                          title: 'Fluxo diário',
                          child: dashboardLineChart(
                            context: context,
                            points: dashList(charts?['fluxoDiario']),
                            valueKey: 'saldo',
                            labelKey: 'data',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: dashboardChartCard(
                          context: context,
                          title: 'Fluxo mensal',
                          child: dashboardLineChart(
                            context: context,
                            points: dashList(charts?['fluxoMensal']),
                            valueKey: 'saldo',
                            labelKey: 'mes',
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: dashboardChartCard(
                          context: context,
                          title: 'Evolução financeira',
                          child: dashboardDualLineChart(
                            context: context,
                            points: dashList(charts?['evolucaoFinanceira']),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: dashboardChartCard(
                          context: context,
                          title: 'Métodos de pagamento',
                          child: dashboardBarChart(
                            context: context,
                            points: dashList(charts?['metodosPagamento']),
                            valueKey: 'total',
                            labelKey: 'metodo',
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Contas vencidas',
                headers: const ['Cliente', 'Saldo', 'Vencimento'],
                reloadKey: '${_query.reloadKey}-contas',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.financeDashboardTable(
                    table: 'contasVencidas',
                    query: _query.copyWith(
                      sortBy: sortBy,
                      sortDir: sortDir,
                      clearSortBy: sortBy == null,
                    ),
                    page: page,
                    pageSize: pageSize,
                  );
                  return DashboardPagedTableResult.fromMap(result);
                },
                rowBuilder: (row) => [
                  row['clienteNome']?.toString() ?? '—',
                  '${row['saldo'] ?? 0} MZN',
                  dashLabel(row['vencimento']),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Últimos pagamentos',
                headers: const ['Fatura', 'Método', 'Valor'],
                reloadKey: '${_query.reloadKey}-pagamentos',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.financeDashboardTable(
                    table: 'ultimosPagamentos',
                    query: _query.copyWith(
                      sortBy: sortBy,
                      sortDir: sortDir,
                      clearSortBy: sortBy == null,
                    ),
                    page: page,
                    pageSize: pageSize,
                  );
                  return DashboardPagedTableResult.fromMap(result);
                },
                rowBuilder: (row) => [
                  row['faturaNumero']?.toString() ?? '—',
                  row['metodo']?.toString() ?? '—',
                  '${row['valor'] ?? 0} MZN',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Últimas receitas',
                headers: const ['Tipo', 'Referência', 'Valor', 'Data'],
                reloadKey: '${_query.reloadKey}-receitas',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.financeDashboardTable(
                    table: 'ultimasReceitas',
                    query: _query.copyWith(
                      sortBy: sortBy,
                      sortDir: sortDir,
                      clearSortBy: sortBy == null,
                    ),
                    page: page,
                    pageSize: pageSize,
                  );
                  return DashboardPagedTableResult.fromMap(result);
                },
                rowBuilder: (row) => [
                  row['tipo']?.toString() ?? '—',
                  row['referencia']?.toString() ?? '—',
                  '${row['valor'] ?? 0} MZN',
                  dashLabel(row['createdAt']),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Últimas despesas',
                headers: const ['Tipo', 'Referência', 'Valor', 'Data'],
                reloadKey: '${_query.reloadKey}-despesas',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.financeDashboardTable(
                    table: 'ultimasDespesas',
                    query: _query.copyWith(
                      sortBy: sortBy,
                      sortDir: sortDir,
                      clearSortBy: sortBy == null,
                    ),
                    page: page,
                    pageSize: pageSize,
                  );
                  return DashboardPagedTableResult.fromMap(result);
                },
                rowBuilder: (row) => [
                  row['tipo']?.toString() ?? '—',
                  row['referencia']?.toString() ?? '—',
                  '${row['valor'] ?? 0} MZN',
                  dashLabel(row['createdAt']),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
