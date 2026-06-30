import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../core/constants/report_paths.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/dashboard_query.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_charts_section.dart';
import '../widgets/dashboard_header_actions.dart';
import '../widgets/dashboard_kpi_section.dart';
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
    final dataSource = ref.watch(dashboardRemoteDataSourceProvider);
    final tables = dashMap(async.valueOrNull?['tables']);
    final charts = dashMap(async.valueOrNull?['charts']);
    final statusOptions = dashboardUniqueOptions(
      dashList(tables?['ultimosPagamentos']).map((row) => row['status']),
    );
    final paymentMethodOptions = dashboardUniqueOptions([
      ...dashList(charts?['metodosPagamento']).map((row) => row['metodo']),
      ...dashList(tables?['ultimosPagamentos']).map((row) => row['metodo']),
    ]);

    return EnterpriseModuleHub(
      scrollable: true,
      filters: DashboardPeriodFilters(
        query: _query,
        onChanged: (query) => setState(() => _query = query),
        statusOptions: statusOptions,
        paymentMethodOptions: paymentMethodOptions,
        actions: [
          DashboardHeaderActions(
            onRefresh: () => ref.invalidate(financeDashboardProvider(_query)),
            reportPath: ReportPaths.dashboardFinance,
            query: _query,
            exportEnabled: async.valueOrNull != null,
            exportSuccessMessage: 'Exportação do painel financeiro concluída.',
          ),
        ],
      ),
      child: dashboardAsyncBody(
        async: async,
        onRetry: () => ref.invalidate(financeDashboardProvider(_query)),
        loadingKpiCount: 5,
        builder: (data) {
          final kpis = dashMap(data['kpis']);
          final charts = dashMap(data['charts']);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardKpiSection(
                primaryKpis: _financePrimaryKpis(kpis),
                secondaryKpis: _financeSecondaryKpis(kpis),
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardChartsSection(
                charts: [
                  dashboardChartCard(
                    context: context,
                    title: 'Receitas x despesas',
                    child: dashboardDualLineChart(
                      context: context,
                      points: dashList(charts?['receitasDespesas']),
                    ),
                  ),
                  DashboardChartSlot(
                    fullWidth: true,
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
                  DashboardChartSlot(
                    fullWidth: true,
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
                  dashboardChartCard(
                    context: context,
                    title: 'Evolução financeira',
                    child: dashboardDualLineChart(
                      context: context,
                      points: dashList(charts?['evolucaoFinanceira']),
                    ),
                  ),
                  dashboardChartCard(
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
                ],
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

List<EnterpriseStatCard> _financePrimaryKpis(Map<String, dynamic>? kpis) {
  if (kpis == null) return const [];
  return [
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
  ];
}

List<EnterpriseStatCard> _financeSecondaryKpis(Map<String, dynamic>? kpis) {
  if (kpis == null) return const [];
  return [
    dashboardKpiCard(
      title: 'Fluxo caixa',
      value: '${dashKpi(kpis, 'fluxoCaixa')} MZN',
      icon: Icons.swap_horiz_outlined,
      accent: StatCardAccent.info,
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
  ];
}
