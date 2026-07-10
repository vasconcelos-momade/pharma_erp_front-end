import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';

import '../../../../core/constants/report_paths.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/navigation/app_nav_config.dart';
import '../../../dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../../dashboard/domain/dashboard_query.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_charts_section.dart';
import '../../../dashboard/presentation/widgets/dashboard_period_filters.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../widgets/finance_report_exports.dart';

class CashflowPage extends ConsumerStatefulWidget {
  const CashflowPage({super.key});

  @override
  ConsumerState<CashflowPage> createState() => _CashflowPageState();
}

class _CashflowPageState extends ConsumerState<CashflowPage> {
  var _query = const DashboardQuery();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(financeDashboardProvider(_query));
    final reportState = ref.watch(reportControllerProvider);
    final dataSource = ref.watch(dashboardRemoteDataSourceProvider);
    final kpis = dashMap(async.valueOrNull?['kpis']);

    return EnterpriseModuleHub(
      title: 'Fluxo de caixa',
      subtitle: 'Tesouraria, movimentos financeiros e evolução do saldo.',
      tag: AppNavSections.finance,
      scrollable: true,
      mobileKpisHorizontalScroll: true,
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutePaths.pos),
          icon: const Icon(Icons.remove_circle_outline),
          label: const Text('Saída'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutePaths.pos),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Suprimento'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutePaths.pos),
          icon: const Icon(Icons.savings_outlined),
          label: const Text('Sangria'),
        ),
        ...financeReportActions(
          ref: ref,
          enabled: !reportState.isSubmitting,
          path: ReportPaths.financeCashflow,
          queryParameters: _query.toParams(),
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
      ),
      kpis: kpis == null
          ? null
          : [
              dashboardKpiCard(
                title: 'Saldo caixa',
                value: '${dashKpi(kpis, 'saldoAtual')} MZN',
                icon: Icons.account_balance_wallet,
                accent: StatCardAccent.positive,
              ),
              dashboardKpiCard(
                title: 'Fluxo caixa',
                value: '${dashKpi(kpis, 'fluxoCaixa')} MZN',
                icon: Icons.swap_horiz_outlined,
                accent: StatCardAccent.info,
              ),
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
            ],
      child: dashboardAsyncBody(
        async: async,
        onRetry: () => ref.invalidate(financeDashboardProvider(_query)),
        builder: (data) {
          final chartData = dashMap(data['charts']);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardChartsSection(
                charts: [
                  DashboardChartSlot(
                    fullWidth: true,
                    child: dashboardChartCard(
                      context: context,
                      title: 'Fluxo diário',
                      child: dashboardLineChart(
                        context: context,
                        points: dashList(chartData?['fluxoDiario']),
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
                        points: dashList(chartData?['fluxoMensal']),
                        valueKey: 'saldo',
                        labelKey: 'mes',
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  dashboardChartCard(
                    context: context,
                    title: 'Receitas x despesas',
                    child: dashboardDualLineChart(
                      context: context,
                      points: dashList(chartData?['receitasDespesas']),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Movimentos financeiros',
                headers: const ['Data', 'Tipo', 'Referência', 'Valor (MZN)'],
                reloadKey: '${_query.reloadKey}-fluxo',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.financeDashboardTable(
                    table: 'fluxoCaixa',
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
                  dashLabel(row['createdAt']),
                  row['tipo']?.toString() ?? '—',
                  row['referencia']?.toString() ?? '—',
                  '${row['valor'] ?? 0} MZN',
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
