import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/report_paths.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/dashboard_query.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_period_filters.dart';
import '../widgets/dashboard_widgets.dart';

class PharmacyDashboardPage extends ConsumerStatefulWidget {
  const PharmacyDashboardPage({super.key});

  @override
  ConsumerState<PharmacyDashboardPage> createState() =>
      _PharmacyDashboardPageState();
}

class _PharmacyDashboardPageState extends ConsumerState<PharmacyDashboardPage> {
  var _query = const DashboardQuery();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pharmacyDashboardProvider(_query));
    final reportState = ref.watch(reportControllerProvider);
    final dataSource = ref.watch(dashboardRemoteDataSourceProvider);
    final kpis = dashMap(async.valueOrNull?['kpis']);
    final tables = dashMap(async.valueOrNull?['tables']);
    final charts = dashMap(async.valueOrNull?['charts']);
    final statusOptions = dashboardUniqueOptions(
      dashList(
        tables?['ultimasDispensacoes'],
      ).map((row) => row['tipoDispensacao']),
      labels: const {
        'VENDA_LIVRE': 'Venda livre',
        'RECEITA_OBRIGATORIA': 'Receita obrigatória',
        'RECEITA_CONTROLADA': 'Receita controlada',
        'PSICOTROPICO': 'Psicotrópico',
        'NARCOTICO': 'Narcótico',
      },
    );
    final movementTypeOptions = dashboardUniqueOptions(
      dashList(charts?['entradasSaidas']).map((row) => row['tipo']),
      labels: const {'ENTRADA': 'Entrada', 'SAIDA': 'Saída'},
    );

    Future<void> exportDashboard({String format = 'csv'}) async {
      if (async.valueOrNull == null || reportState.isSubmitting) return;
      await dashboardReportExport(
        ref: ref,
        path: ReportPaths.dashboardPharmacy,
        query: _query,
        format: format,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exportação do painel farmácia concluída.'),
        ),
      );
    }

    return EnterpriseModuleHub(
      title: 'Painel da farmácia',
      subtitle: 'Produtos, regulação, validades, FEFO e dispensações.',
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
          onPressed: () => ref.invalidate(pharmacyDashboardProvider(_query)),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      filters: DashboardPeriodFilters(
        query: _query,
        onChanged: (query) => setState(() => _query = query),
        showCategoryFilter: true,
        showProductFilter: true,
        statusOptions: statusOptions,
        movementTypeOptions: movementTypeOptions,
        extraFilters: [
          ActionChip(
            label: const Text('Validades'),
            onPressed: () => context.go(AppRoutePaths.pharmacyExpiry),
          ),
          ActionChip(
            label: const Text('FEFO'),
            onPressed: () => context.go(AppRoutePaths.pharmacyFefo),
          ),
          ActionChip(
            label: const Text('Lotes'),
            onPressed: () => context.go(AppRoutePaths.pharmacyLots),
          ),
          ActionChip(
            label: const Text('Produtos'),
            onPressed: () => context.go(AppRoutePaths.products),
          ),
        ],
      ),
      kpis: kpis == null
          ? null
          : [
              dashboardKpiCard(
                title: 'Produtos',
                value: dashKpi(kpis, 'produtosCadastrados'),
                icon: Icons.medication_outlined,
              ),
              dashboardKpiCard(
                title: 'Produtos activos',
                value: dashKpi(kpis, 'produtosAtivos'),
                icon: Icons.check_circle_outline,
                accent: StatCardAccent.positive,
              ),
              dashboardKpiCard(
                title: 'Categorias',
                value: dashKpi(kpis, 'categorias'),
                icon: Icons.category_outlined,
              ),
              dashboardKpiCard(
                title: 'Sem stock',
                value: dashKpi(kpis, 'produtosSemStock'),
                icon: Icons.inventory_2_outlined,
                accent: StatCardAccent.warning,
              ),
              dashboardKpiCard(
                title: 'Abaixo mínimo',
                value: dashKpi(kpis, 'produtosAbaixoMinimo'),
                icon: Icons.vertical_align_bottom_outlined,
                accent: StatCardAccent.warning,
              ),
              dashboardKpiCard(
                title: 'Antimicrobianos',
                value: dashKpi(kpis, 'antimicrobianos'),
                icon: Icons.biotech_outlined,
              ),
              dashboardKpiCard(
                title: 'Controlados',
                value: dashKpi(kpis, 'produtosControlados'),
                icon: Icons.verified_user_outlined,
              ),
              dashboardKpiCard(
                title: 'Valor stock',
                value: '${dashKpi(kpis, 'valorTotalStock')} MZN',
                icon: Icons.payments_outlined,
              ),
              dashboardKpiCard(
                title: 'Psicotrópicos',
                value: dashKpi(kpis, 'psicotropicos'),
                icon: Icons.science_outlined,
                accent: StatCardAccent.info,
              ),
              dashboardKpiCard(
                title: 'Próx. validade',
                value: dashKpi(kpis, 'produtosProximosValidade'),
                icon: Icons.event_busy,
                accent: StatCardAccent.danger,
              ),
              dashboardKpiCard(
                title: 'Alertas',
                value: dashKpi(kpis, 'alertasAbertos'),
                icon: Icons.notifications_active_outlined,
              ),
              dashboardKpiCard(
                title: 'Alertas sanit.',
                value: dashKpi(kpis, 'alertasSanitarios'),
                icon: Icons.health_and_safety_outlined,
                accent: StatCardAccent.danger,
              ),
              dashboardKpiCard(
                title: 'Lotes activos',
                value: dashKpi(kpis, 'lotesAtivos'),
                icon: Icons.layers_outlined,
              ),
              dashboardKpiCard(
                title: 'Sem fornecedor',
                value: dashKpi(kpis, 'produtosSemFornecedor'),
                icon: Icons.local_shipping_outlined,
                accent: StatCardAccent.warning,
              ),
            ],
      child: dashboardAsyncBody(
        async: async,
        onRetry: () => ref.invalidate(pharmacyDashboardProvider(_query)),
        builder: (data) {
          final charts = dashMap(data['charts']);
          final validades = dashMap(charts?['validades']) ?? const {};
          final fefo = dashMap(charts?['fefo']) ?? const {};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, bx) {
                  final narrow = bx.maxWidth < 520;
                  final validadesChart = dashboardChartCard(
                    context: context,
                    title: 'Validades por prazo',
                    child: dashboardIndexedBarChart(
                      context: context,
                      labels: const ['Exp.', '30d', '60d'],
                      values: [
                        (validades['lotesExpirados'] as num?)?.toDouble() ?? 0,
                        (validades['expiramEm30Dias'] as num?)?.toDouble() ?? 0,
                        (validades['expiramEm60Dias'] as num?)?.toDouble() ?? 0,
                      ],
                      barColors: [
                        context.pharmaTokens.posDanger,
                        context.pharmaTokens.posWarning,
                        context.pharmaTokens.brandBlue,
                      ],
                      barWidth: 28,
                    ),
                  );
                  final t = context.pharmaTokens;
                  final fefoChart = dashboardChartCard(
                    context: context,
                    title: 'Distribuição FEFO',
                    child: dashboardPieChart(
                      context: context,
                      slices: [
                        DashboardPieSlice(
                          label: 'FEFO',
                          value:
                              (fefo['produtosForaFefo'] as num?)?.toDouble() ??
                              0,
                          color: t.posDanger,
                        ),
                        DashboardPieSlice(
                          label: 'Exp.',
                          value:
                              (fefo['lotesExpirados'] as num?)?.toDouble() ?? 0,
                          color: t.posWarning,
                        ),
                        DashboardPieSlice(
                          label: 'Bloq.',
                          value:
                              (fefo['lotesBloqueados'] as num?)?.toDouble() ??
                              0,
                          color: t.brandBlue,
                        ),
                        DashboardPieSlice(
                          label: 'Alert.',
                          value: (fefo['alertasFefo'] as num?)?.toDouble() ?? 0,
                          color: t.brandGreen,
                        ),
                      ],
                    ),
                  );
                  if (narrow) {
                    return Column(
                      children: [
                        validadesChart,
                        SizedBox(height: context.spacing.md),
                        fefoChart,
                      ],
                    );
                  }
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: validadesChart),
                        SizedBox(width: context.spacing.lg),
                        Expanded(child: fefoChart),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
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
                          title: 'Produtos por categoria',
                          child: dashboardBarChart(
                            context: context,
                            points: dashList(charts?['produtosPorCategoria']),
                            valueKey: 'totalProdutos',
                            labelKey: 'categoria',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: dashboardChartCard(
                          context: context,
                          title: 'Produtos por regulação',
                          child: dashboardBarChart(
                            context: context,
                            points: dashList(charts?['produtosPorRegulacao']),
                            valueKey: 'total',
                            labelKey: 'regulacao',
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: dashboardChartCard(
                          context: context,
                          title: 'Stock por categoria',
                          child: dashboardBarChart(
                            context: context,
                            points: dashList(charts?['stockPorCategoria']),
                            valueKey: 'stock',
                            labelKey: 'categoria',
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: dashboardChartCard(
                          context: context,
                          title: 'Entradas x saídas',
                          child: dashboardBarChart(
                            context: context,
                            points: dashList(charts?['entradasSaidas']),
                            valueKey: 'quantidade',
                            labelKey: 'tipo',
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: dashboardChartCard(
                          context: context,
                          title: 'Produtos mais dispensados',
                          child: dashboardBarChart(
                            context: context,
                            points: dashList(
                              charts?['produtosMaisDispensados'],
                            ),
                            valueKey: 'quantidade',
                            labelKey: 'produtoNome',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Produtos críticos',
                headers: const ['Produto', 'Disponível', 'Mínimo'],
                reloadKey: '${_query.reloadKey}-criticos',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.pharmacyDashboardTable(
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
                  row['nome']?.toString() ?? '—',
                  '${row['disponivel'] ?? 0}',
                  '${row['minimo'] ?? 0}',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Últimas entradas',
                headers: const ['Produto', 'Lote', 'Qtd', 'Origem'],
                reloadKey: '${_query.reloadKey}-entradas',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.pharmacyDashboardTable(
                    table: 'ultimasEntradas',
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
                  row['numeroLote']?.toString() ?? '—',
                  '${row['quantidade'] ?? 0}',
                  row['origem']?.toString() ?? '—',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Últimas dispensações',
                headers: const ['Produto', 'Lote', 'Qtd', 'Tipo'],
                reloadKey: '${_query.reloadKey}-dispensacoes',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.pharmacyDashboardTable(
                    table: 'ultimasDispensacoes',
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
                  row['numeroLote']?.toString() ?? '—',
                  '${row['quantidade'] ?? 0}',
                  row['tipoDispensacao']?.toString() ?? '—',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DashboardPaginatedTable(
                title: 'Últimos alertas',
                headers: const ['Produto', 'Tipo', 'Mensagem'],
                reloadKey: '${_query.reloadKey}-alertas',
                loadPage: (page, pageSize, sortBy, sortDir) async {
                  final result = await dataSource.pharmacyDashboardTable(
                    table: 'ultimosAlertas',
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
            ],
          );
        },
      ),
    );
  }
}
