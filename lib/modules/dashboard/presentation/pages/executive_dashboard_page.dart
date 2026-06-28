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

class ExecutiveDashboardPage extends ConsumerStatefulWidget {
  const ExecutiveDashboardPage({super.key});

  @override
  ConsumerState<ExecutiveDashboardPage> createState() =>
      _ExecutiveDashboardPageState();
}

class _ExecutiveDashboardPageState
    extends ConsumerState<ExecutiveDashboardPage> {
  var _query = const DashboardQuery();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(executiveDashboardProvider(_query));
    final reportState = ref.watch(reportControllerProvider);
    final dataSource = ref.watch(dashboardRemoteDataSourceProvider);
    final kpis = dashMap(async.valueOrNull?['kpis']);
    final tables = dashMap(async.valueOrNull?['tables']);
    final charts = dashMap(async.valueOrNull?['charts']);
    final statusOptions = dashboardUniqueOptions(
      dashList(tables?['ultimasVendas']).map((row) => row['estado']),
    );
    final paymentMethodOptions = dashboardUniqueOptions([
      ...dashList(charts?['metodosPagamento']).map((row) => row['metodo']),
      ...dashList(tables?['ultimasVendas']).map((row) => row['tipoPagamento']),
    ]);

    Future<void> exportDashboard({String format = 'csv'}) async {
      if (async.valueOrNull == null || reportState.isSubmitting) return;
      await dashboardReportExport(
        ref: ref,
        path: ReportPaths.dashboardExecutive,
        query: _query,
        format: format,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exportação do painel executivo concluída.'),
        ),
      );
    }

    return EnterpriseModuleHub(
      title: 'Painel executivo',
      subtitle:
          'Visão consolidada de vendas, finanças, stock e alertas operacionais.',
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
          onPressed: () => ref.invalidate(executiveDashboardProvider(_query)),
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
                title: 'Receita hoje',
                value: '${dashKpi(kpis, 'receitaHoje')} MZN',
                icon: Icons.payments_outlined,
                accent: StatCardAccent.positive,
              ),
              dashboardKpiCard(
                title: 'Receita mês',
                value: '${dashKpi(kpis, 'receitaMes')} MZN',
                icon: Icons.calendar_month_outlined,
                accent: StatCardAccent.info,
              ),
              dashboardKpiCard(
                title: 'Lucro bruto',
                value: '${dashKpi(kpis, 'lucroBruto')} MZN',
                icon: Icons.insights_outlined,
                accent: StatCardAccent.info,
              ),
              dashboardKpiCard(
                title: 'Lucro líquido',
                value: '${dashKpi(kpis, 'lucroLiquido')} MZN',
                icon: Icons.trending_up,
                accent: StatCardAccent.positive,
              ),
              dashboardKpiCard(
                title: 'Total vendas',
                value: '${dashKpi(kpis, 'totalVendas')} MZN',
                icon: Icons.point_of_sale_outlined,
              ),
              dashboardKpiCard(
                title: 'Ticket médio',
                value: '${dashKpi(kpis, 'ticketMedio')} MZN',
                icon: Icons.receipt_long_outlined,
              ),
              dashboardKpiCard(
                title: 'Faturas mês',
                value: dashKpi(kpis, 'numeroFaturas'),
                icon: Icons.description_outlined,
              ),
              dashboardKpiCard(
                title: 'Produtos vendidos',
                value: dashKpi(kpis, 'produtosVendidos'),
                icon: Icons.shopping_bag_outlined,
              ),
              dashboardKpiCard(
                title: 'Clientes activos',
                value: dashKpi(kpis, 'clientesAtivos'),
                icon: Icons.people_outline,
              ),
              dashboardKpiCard(
                title: 'Contas a receber',
                value: '${dashKpi(kpis, 'contasReceber')} MZN',
                icon: Icons.call_received_outlined,
                accent: StatCardAccent.positive,
              ),
              dashboardKpiCard(
                title: 'Contas a pagar',
                value: '${dashKpi(kpis, 'contasPagar')} MZN',
                icon: Icons.call_made_outlined,
                accent: StatCardAccent.warning,
              ),
              dashboardKpiCard(
                title: 'Stock total',
                value: dashKpi(kpis, 'stockTotal'),
                icon: Icons.inventory_outlined,
              ),
              dashboardKpiCard(
                title: 'Stock crítico',
                value: dashKpi(kpis, 'produtosCriticos'),
                icon: Icons.inventory_2_outlined,
                accent: StatCardAccent.danger,
              ),
              dashboardKpiCard(
                title: 'Valor inventário',
                value: '${dashKpi(kpis, 'valorInventario')} MZN',
                icon: Icons.warehouse_outlined,
              ),
              dashboardKpiCard(
                title: 'Lotes expirados',
                value: dashKpi(kpis, 'lotesExpirados'),
                icon: Icons.event_busy_outlined,
                accent: StatCardAccent.danger,
              ),
              dashboardKpiCard(
                title: 'Próx. validade',
                value: dashKpi(kpis, 'produtosProximosValidade'),
                icon: Icons.warning_amber_outlined,
                accent: StatCardAccent.warning,
              ),
            ],
      child: dashboardAsyncBody(
        async: async,
        onRetry: () => ref.invalidate(executiveDashboardProvider(_query)),
        loadingKpiCount: 16,
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
                          title: 'Receita diária',
                          child: dashboardLineChart(
                            context: context,
                            points: dashList(charts?['receitaDiaria']),
                            valueKey: 'total',
                            labelKey: 'data',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: dashboardChartCard(
                          context: context,
                          title: 'Receita mensal',
                          child: dashboardLineChart(
                            context: context,
                            points: dashList(charts?['receitaMensal']),
                            valueKey: 'total',
                            labelKey: 'mes',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: dashboardChartCard(
                          context: context,
                          title: 'Fluxo financeiro',
                          child: dashboardDualLineChart(
                            context: context,
                            points: dashList(charts?['fluxoFinanceiro']),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: dashboardChartCard(
                          context: context,
                          title: 'Evolução das vendas',
                          child: dashboardLineChart(
                            context: context,
                            points: dashList(charts?['evolucaoVendas']),
                            valueKey: 'total',
                            labelKey: 'data',
                            color: Theme.of(context).colorScheme.tertiary,
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
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: dashboardChartCard(
                          context: context,
                          title: 'Top produtos vendidos',
                          child: dashboardBarChart(
                            context: context,
                            points: dashList(charts?['topProdutos']),
                            valueKey: 'total',
                            labelKey: 'produtoNome',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: dashboardChartCard(
                          context: context,
                          title: 'Top categorias',
                          child: dashboardBarChart(
                            context: context,
                            points: dashList(charts?['topCategorias']),
                            valueKey: 'total',
                            labelKey: 'categoria',
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
                title: 'Últimas vendas',
                headers: const ['Fatura', 'Cliente', 'Total', 'Estado'],
                columns: const [
                  DashboardTableColumn(label: 'Fatura', sortKey: 'numero'),
                  DashboardTableColumn(label: 'Cliente'),
                  DashboardTableColumn(label: 'Total', sortKey: 'total'),
                  DashboardTableColumn(label: 'Estado'),
                ],
                reloadKey: '${_query.reloadKey}-vendas',
                initialSortBy: 'numero',
                initialSortDir: 'desc',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.executiveDashboardTable(
                    table: 'ultimasVendas',
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
                  row['numero']?.toString() ?? '—',
                  row['clienteNome']?.toString() ?? '—',
                  '${row['total'] ?? 0} MZN',
                  row['estado']?.toString() ?? '—',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Alertas críticos',
                headers: const ['Produto', 'Tipo', 'Mensagem'],
                reloadKey: '${_query.reloadKey}-alertas',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.executiveDashboardTable(
                    table: 'alertasCriticos',
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
                  row['produtoNome']?.toString() ?? '—',
                  row['tipo']?.toString() ?? '—',
                  row['mensagem']?.toString() ?? '—',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Últimos eventos de negócio',
                headers: const ['Tipo', 'Entidade', 'Utilizador', 'Data'],
                reloadKey: '${_query.reloadKey}-eventos',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.executiveDashboardTable(
                    table: 'ultimosEventos',
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
                  row['type']?.toString() ?? '—',
                  row['entity']?.toString() ?? '—',
                  row['userNome']?.toString() ?? '—',
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
