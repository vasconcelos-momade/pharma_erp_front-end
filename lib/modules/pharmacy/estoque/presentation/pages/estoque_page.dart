import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../app/providers/auth_session_notifier.dart';
import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/responsive/responsive_builder.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../presentation/widgets/pharmacy_report_exports.dart';
import '../../../../stock/data/datasources/fornecedor_remote_datasource.dart';
import '../../domain/entities/estoque_item.dart';
import '../providers/estoque_provider.dart';
import '../widgets/estoque_empty_state.dart';
import '../widgets/estoque_filters_bottom_sheet.dart';
import '../widgets/estoque_loading.dart';
import '../widgets/estoque_mobile_list.dart';
import '../widgets/estoque_pagination.dart';
import '../widgets/estoque_table.dart';
import '../widgets/estoque_toolbar.dart';

/// Gestão unificada de stock e lotes — padrão enterprise alinhado a Produtos/PDV.
class EstoquePage extends ConsumerStatefulWidget {
  const EstoquePage({super.key});

  @override
  ConsumerState<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends ConsumerState<EstoquePage> {
  final TextEditingController _searchController = TextEditingController();
  List<({String id, String nome})> _fornecedores = const [];
  List<EstoqueItem> _accumulatedItems = [];

  @override
  void initState() {
    super.initState();
    _loadFornecedores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFornecedores() async {
    try {
      final response = await ref.read(fornecedorRemoteDataSourceProvider).search(
            pageSize: 100,
          );
      if (!mounted) return;
      setState(() {
        _fornecedores = response.items
            .map((f) => (id: f.id, nome: f.nome))
            .toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final t = context.pharmaTokens;
    final state = ref.watch(estoqueListProvider);
    final controller = ref.read(estoqueListProvider.notifier);
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final authReady = ref.watch(
      authSessionProvider.select(
        (session) => !session.isBootstrapping && session.hasTenantContext,
      ),
    );
    final categories = authReady
        ? (categoriesAsync.asData?.value ?? const <Category>[])
        : const <Category>[];

    if (_searchController.text != state.query) {
      _searchController.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    ref.listen(estoqueListProvider, (prev, next) {
      if (prev?.page != next.page ||
          prev?.query != next.query ||
          prev?.categoriaId != next.categoriaId ||
          prev?.fornecedorId != next.fornecedorId ||
          prev?.estadoSanitario != next.estadoSanitario ||
          prev?.disponibilidade != next.disponibilidade ||
          prev?.semStock != next.semStock ||
          prev?.aExpirar != next.aExpirar ||
          prev?.expirado != next.expirado) {
        if (next.page == 1) {
          _accumulatedItems = List.of(next.items);
        } else {
          final newItems = next.items
              .where((e) => !_accumulatedItems.any((a) => a.id == e.id))
              .toList();
          _accumulatedItems.addAll(newItems);
        }
      } else if (prev?.items != next.items && next.page == 1) {
        _accumulatedItems = List.of(next.items);
      }
    });

    final dash = state.dashboard;
    final currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 0);
    final kpis = dash == null
        ? null
        : [
            EnterpriseStatCard(
              title: 'Produtos em stock',
              value: '${dash.produtosEmStock}',
              icon: Icons.inventory_outlined,
            ),
            EnterpriseStatCard(
              title: 'Lotes ativos',
              value: '${dash.lotesAtivos}',
              icon: Icons.layers_outlined,
            ),
            EnterpriseStatCard(
              title: 'Produtos sem stock',
              value: '${dash.produtosSemStock}',
              icon: Icons.remove_shopping_cart_outlined,
            ),
            EnterpriseStatCard(
              title: 'Lotes a expirar',
              value: '${dash.lotesAExpirar}',
              icon: Icons.schedule_outlined,
            ),
            EnterpriseStatCard(
              title: 'Lotes expirados',
              value: '${dash.lotesExpirados}',
              icon: Icons.warning_amber_outlined,
            ),
            EnterpriseStatCard(
              title: 'Valor inventário',
              value: currency.format(dash.valorTotalInventario),
              icon: Icons.payments_outlined,
            ),
          ];

    final reportQuery = <String, dynamic>{
      if (state.query.isNotEmpty) 'q': state.query,
      if (state.categoriaId != null) 'categoriaId': state.categoriaId,
      if (state.fornecedorId != null) 'fornecedorId': state.fornecedorId,
      if (state.estadoSanitario != null) 'estadoSanitario': state.estadoSanitario,
      if (state.disponibilidade != null) 'disponibilidade': state.disponibilidade,
      if (state.expirado == true) 'expirado': true,
    };

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.isDesktopOrWider;
        final isMobile = !constraints.isTabletOrWider;

        return Scaffold(
          backgroundColor: t.bgPrimary,
          body: EnterpriseModuleHub(
            title: 'Estoque',
            subtitle: 'Gestão unificada de stock e lotes com validades, sanidade e disponibilidade.',
            mobileKpisHorizontalScroll: true,
            kpis: kpis,
            filters: isMobile
                ? null
                : EstoqueToolbar(
                    searchController: _searchController,
                    state: state,
                    controller: controller,
                    categories: categories,
                    fornecedores: _fornecedores,
                    onSearchChanged: controller.onSearchChanged,
                    onOpenMobileFilters: () => _openFilters(context, controller, state, categories),
                  ),
            actions: isMobile
                ? null
                : [
                    OutlinedButton.icon(
                      onPressed: state.isLoading ? null : controller.refreshCurrentPage,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Atualizar'),
                    ),
                    ...pharmacyReportActions(
                      ref: ref,
                      enabled: !state.isLoading,
                      path: state.expirado == true
                          ? ReportPaths.pharmacyLotsExpired
                          : ReportPaths.pharmacyLotsActive,
                      queryParameters: reportQuery,
                      isIconButton: false,
                    ),
                  ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isMobile) ...[
                  EstoqueMobileToolbar(
                    searchController: _searchController,
                    state: state,
                    controller: controller,
                    onSearchChanged: controller.onSearchChanged,
                    onOpenFilters: () => _openFilters(context, controller, state, categories),
                    reportAction: pharmacyReportActions(
                      ref: ref,
                      enabled: !state.isLoading,
                      path: state.expirado == true
                          ? ReportPaths.pharmacyLotsExpired
                          : ReportPaths.pharmacyLotsActive,
                      queryParameters: reportQuery,
                      expandChild: true,
                      buttonLabel: 'Exportar..',
                    ).single,
                  ),
                  SizedBox(height: s.sm),
                ],
                if (!isMobile && state.isLoading && !state.isInitialized)
                  const LinearProgressIndicator(),
                if (state.errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: s.sm),
                    child: Text(
                      state.errorMessage!,
                      style: Theme.of(context).textTheme.erpBody.copyWith(color: t.posDanger),
                    ),
                  ),
                Expanded(
                  child: !state.isInitialized && state.isLoading
                      ? EstoqueLoading(isDesktop: isDesktop)
                      : state.errorMessage != null && state.items.isEmpty
                          ? ModuleErrorState(
                              title: 'Erro ao carregar estoque',
                              message: state.errorMessage!,
                              onRetry: () => controller.refreshCurrentPage(),
                            )
                      : (isDesktop ? state.items.isEmpty : _accumulatedItems.isEmpty)
                          ? const EstoqueEmptyState()
                          : isMobile
                              ? EnterpriseMobileScrollList(
                                  kpis: kpis,
                                  stickyHeader: const SizedBox.shrink(),
                                  itemCount: _accumulatedItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _accumulatedItems[index];
                                    return EstoqueMobileCard(
                                      item: item,
                                      isBusy: state.actionLoteId == item.id,
                                    );
                                  },
                                  hasMore: state.hasMore,
                                  isLoading: state.isLoading,
                                  onLoadMore: () => controller.goToPage(state.page + 1),
                                  emptyMessage: 'Nenhum lote encontrado',
                                  totalCount: state.totalCount,
                                  totalCountLabel: state.totalCount != null
                                      ? 'Total: ${state.totalCount} lote(s)'
                                      : null,
                                )
                              : EstoqueTable(
                                  items: state.items,
                                  actionLoteId: state.actionLoteId,
                                ),
                ),
                if (isDesktop && state.isInitialized && state.totalCount != null)
                  EstoquePagination(
                    page: state.page,
                    pageSize: state.pageSize,
                    totalCount: state.totalCount!,
                    isBusy: state.isLoading,
                    onPageChanged: controller.goToPage,
                    onPageSizeChanged: controller.setPageSize,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFilters(
    BuildContext context,
    EstoqueListController controller,
    EstoqueListState state,
    List<Category> categories,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EstoqueFiltersBottomSheet(
        initialState: state,
        categories: categories,
        fornecedores: _fornecedores,
        onApply: ({
          categoriaId,
          fornecedorId,
          estadoSanitario,
          disponibilidade,
          semStock,
          aExpirar,
          expirado,
        }) {
          controller.setCategoriaFilter(categoriaId);
          controller.setFornecedorFilter(fornecedorId);
          controller.setEstadoSanitarioFilter(estadoSanitario);
          controller.setDisponibilidadeFilter(disponibilidade);
          controller.setSemStockFilter(semStock);
          controller.setAExpirarFilter(aExpirar);
          controller.setExpiradoFilter(expirado);
        },
      ),
    );
  }
}
