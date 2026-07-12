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

class StockDashboardPage extends ConsumerStatefulWidget {
  const StockDashboardPage({super.key});

  @override
  ConsumerState<StockDashboardPage> createState() => _StockDashboardPageState();
}

class _StockDashboardPageState extends ConsumerState<StockDashboardPage> {
  var _query = const DashboardQuery();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(stockDashboardProvider(_query));
    final dataSource = ref.watch(dashboardRemoteDataSourceProvider);
    final tables = dashMap(async.valueOrNull?['tables']);
    final charts = dashMap(async.valueOrNull?['charts']);
    final statusOptions = dashboardUniqueOptions([
      ...dashList(tables?['inventarios']).map((row) => row['status']),
      ...dashList(tables?['entradasCompra']).map((row) => row['fornecedorNome']),
    ]);
    final movementTypeOptions = dashboardUniqueOptions(
      [
        ...dashList(charts?['entradasSaidas']).map((row) => row['tipo']),
        ...dashList(tables?['ultimosMovimentos']).map((row) => row['tipo']),
      ],
      labels: const {
        'ENTRADA': 'Entrada',
        'COMPRA': 'Compra',
        'SAIDA': 'Saída',
        'AJUSTE': 'Ajuste',
      },
    );

    return EnterpriseModuleHub(
      scrollable: true,
      filters: DashboardPeriodFilters(
        query: _query,
        onChanged: (query) => setState(() => _query = query),
        showProductFilter: true,
        statusOptions: statusOptions,
        movementTypeOptions: movementTypeOptions,
        actions: [
          DashboardHeaderActions(
            onRefresh: () => ref.invalidate(stockDashboardProvider(_query)),
            reportPath: ReportPaths.dashboardStock,
            query: _query,
            exportEnabled: async.valueOrNull != null,
            exportSuccessMessage: 'Exportação do painel stock concluída.',
          ),
        ],
      ),
      child: dashboardAsyncBody(
        async: async,
        onRetry: () => ref.invalidate(stockDashboardProvider(_query)),
        loadingKpiCount: 5,
        builder: (data) {
          final kpis = dashMap(data['kpis']);
          final charts = dashMap(data['charts']);
          final composicao = dashMap(charts?['composicaoLotes']) ?? const {};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardKpiSection(
                primaryKpis: _stockPrimaryKpis(kpis),
                secondaryKpis: _stockSecondaryKpis(kpis),
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardChartsSection(
                charts: [
                  dashboardChartCard(
                    context: context,
                    title: 'Composição de lotes',
                    child: dashboardIndexedBarChart(
                      context: context,
                      labels: const [
                        'Total',
                        'Disp.',
                        'Sanit.',
                        'Reserv.',
                        'Exp.',
                      ],
                      values: [
                        (composicao['totalLotes'] as num?)?.toDouble() ?? 0,
                        (composicao['lotesDisponiveis'] as num?)?.toDouble() ??
                            0,
                        (composicao['lotesSanitarios'] as num?)?.toDouble() ??
                            0,
                        (composicao['lotesReservados'] as num?)?.toDouble() ??
                            0,
                        (composicao['lotesExpirados'] as num?)?.toDouble() ??
                            0,
                      ],
                    ),
                  ),
                  dashboardChartCard(
                    context: context,
                    title: 'Entradas x saídas',
                    child: dashboardBarChart(
                      context: context,
                      points: dashList(charts?['entradasSaidas']),
                      valueKey: 'quantidade',
                      labelKey: 'tipo',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  DashboardChartSlot(
                    fullWidth: true,
                    child: dashboardChartCard(
                      context: context,
                      title: 'Movimentação mensal',
                      child: dashboardDualLineChart(
                        context: context,
                        points: dashList(charts?['movimentacaoMensal']).map(
                          (row) {
                            return {
                              'receitas': row['entradas'],
                              'despesas': row['saidas'],
                              'mes': row['mes'],
                            };
                          },
                        ).toList(),
                      ),
                    ),
                  ),
                  dashboardChartCard(
                    context: context,
                    title: 'Produtos mais movimentados',
                    child: dashboardBarChart(
                      context: context,
                      points: dashList(charts?['produtosMaisMovimentados']),
                      valueKey: 'quantidade',
                      labelKey: 'produtoNomeComercial',
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  dashboardChartCard(
                    context: context,
                    title: 'Valor stock por categoria',
                    child: dashboardBarChart(
                      context: context,
                      points: dashList(charts?['valorStockPorCategoria']),
                      valueKey: 'valor',
                      labelKey: 'categoria',
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Últimos movimentos',
                headers: const ['Tipo', 'Produto', 'Qtd', 'Origem'],
                reloadKey: '${_query.reloadKey}-mov',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.stockDashboardTable(
                    table: 'ultimosMovimentos',
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
                  row['produtoNomeComercial']?.toString() ??
                      row['produtoNome']?.toString() ?? '—',
                  '${row['quantidade'] ?? 0}',
                  row['origem']?.toString() ?? '—',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Produtos críticos',
                headers: const ['Produto', 'Disponível', 'Mínimo'],
                reloadKey: '${_query.reloadKey}-criticos',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.stockDashboardTable(
                    table: 'produtosCriticos',
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
                  row['nomeComercial']?.toString() ??
                      row['nome']?.toString() ??
                      row['produtoNomeComercial']?.toString() ??
                      '—',
                  '${row['disponivel'] ?? 0}',
                  '${row['minimo'] ?? 0}',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Inventários',
                headers: const ['Código', 'Estado', 'Início'],
                reloadKey: '${_query.reloadKey}-inv',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.stockDashboardTable(
                    table: 'inventarios',
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
                  row['codigo']?.toString() ?? '—',
                  row['status']?.toString() ?? '—',
                  dashLabel(row['iniciadoEm']),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Entradas de compra',
                headers: const ['Produto', 'Lote', 'Fornecedor', 'Valor'],
                reloadKey: '${_query.reloadKey}-entradas-compra',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.stockDashboardTable(
                    table: 'entradasCompra',
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
                  row['produtoNomeComercial']?.toString() ?? '—',
                  row['numeroLote']?.toString() ?? '—',
                  row['fornecedorNome']?.toString() ?? '—',
                  '${row['valorCompra'] ?? 0}',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Reservas',
                headers: const ['Produto', 'Lote', 'Qtd', 'Expira'],
                reloadKey: '${_query.reloadKey}-res',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.stockDashboardTable(
                    table: 'reservas',
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
                  row['produtoNomeComercial']?.toString() ??
                      row['produtoNome']?.toString() ?? '—',
                  row['numeroLote']?.toString() ?? '—',
                  '${row['quantidade'] ?? 0}',
                  dashLabel(row['expiresAt']),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Incinerações',
                headers: const ['Auto', 'Data'],
                reloadKey: '${_query.reloadKey}-inc',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.stockDashboardTable(
                    table: 'incineracoes',
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
                  row['numeroAuto']?.toString() ?? '—',
                  dashLabel(row['dataIncineracao']),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

List<EnterpriseStatCard> _stockPrimaryKpis(Map<String, dynamic>? kpis) {
  if (kpis == null) return const [];
  return [
    dashboardKpiCard(
      title: 'Stock disponível',
      value: dashKpi(kpis, 'stockDisponivel'),
      icon: Icons.inventory_2_outlined,
      accent: StatCardAccent.positive,
    ),
    dashboardKpiCard(
      title: 'Valor stock',
      value: '${dashKpi(kpis, 'valorTotalStock')} MZN',
      icon: Icons.payments_outlined,
    ),
    dashboardKpiCard(
      title: 'Críticos',
      value: dashKpi(kpis, 'produtosCriticos'),
      icon: Icons.warning_amber_outlined,
      accent: StatCardAccent.danger,
    ),
    dashboardKpiCard(
      title: 'Sem stock',
      value: dashKpi(kpis, 'produtosSemStock'),
      icon: Icons.remove_shopping_cart_outlined,
      accent: StatCardAccent.warning,
    ),
    dashboardKpiCard(
      title: 'Lotes activos',
      value: dashKpi(kpis, 'lotesAtivos'),
      icon: Icons.layers_outlined,
    ),
  ];
}

List<EnterpriseStatCard> _stockSecondaryKpis(Map<String, dynamic>? kpis) {
  if (kpis == null) return const [];
  return [
    dashboardKpiCard(
      title: 'Stock total',
      value: dashKpi(kpis, 'stockTotal'),
      icon: Icons.inventory_outlined,
    ),
    dashboardKpiCard(
      title: 'Reservado',
      value: dashKpi(kpis, 'stockReservado'),
      icon: Icons.lock_clock_outlined,
    ),
    dashboardKpiCard(
      title: 'Inventários',
      value: dashKpi(kpis, 'inventariosAbertos'),
      icon: Icons.fact_check_outlined,
    ),
    dashboardKpiCard(
      title: 'Sugestões compra',
      value: dashKpi(kpis, 'sugestoesCompra'),
      icon: Icons.shopping_cart_outlined,
    ),
    dashboardKpiCard(
      title: 'Incinerações',
      value: dashKpi(kpis, 'incineracoes'),
      icon: Icons.delete_sweep_outlined,
      accent: StatCardAccent.warning,
    ),
    dashboardKpiCard(
      title: 'Ajustes stock',
      value: dashKpi(kpis, 'ajustesStock'),
      icon: Icons.tune_outlined,
    ),
    dashboardKpiCard(
      title: 'Alertas operac.',
      value: dashKpi(kpis, 'alertasOperacionais'),
      icon: Icons.crisis_alert_outlined,
      accent: StatCardAccent.danger,
    ),
  ];
}
