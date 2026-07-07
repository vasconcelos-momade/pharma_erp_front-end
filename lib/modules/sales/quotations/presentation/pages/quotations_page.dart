import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/pharma_surface.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/layout/enterprise_module_search_bar.dart';
import '../../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../../pharmacy/products/domain/entities/product.dart';
import '../../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../../../pharmacy/products/presentation/widgets/produto_categoria_filter_dropdown.dart';
import '../../../pdv/domain/entities/pdv_service.dart';
import '../../../pdv/presentation/providers/pdv_service_provider.dart';
import '../../../pdv/presentation/widgets/pdv_catalog_utils.dart';
import '../../../pdv/presentation/widgets/pdv_product_list.dart';
import '../../../pdv/presentation/widgets/pdv_product_table.dart';
import '../../../pdv/presentation/widgets/pdv_service_list.dart';
import '../../../pdv/presentation/widgets/pdv_service_table.dart';
import '../../data/repositories/quotation_repository_impl.dart';
import '../providers/quotation_cart_provider.dart';
import '../widgets/quotation_cart_item_card.dart';
import '../widgets/quotation_cart_summary.dart';
import '../widgets/save_quotation_dialog.dart';

class SalesQuotationsPage extends ConsumerStatefulWidget {
  const SalesQuotationsPage({super.key});

  @override
  ConsumerState<SalesQuotationsPage> createState() => _SalesQuotationsPageState();
}

class _SalesQuotationsPageState extends ConsumerState<SalesQuotationsPage>
    with TickerProviderStateMixin {
  final _search = TextEditingController();
  final _searchFocusNode = FocusNode();
  late final TabController _catalogTabController;
  late final TabController _mobileTabController;
  int _catalogTabIndex = 0;
  List<Product> _accumulatedProducts = [];

  @override
  void initState() {
    super.initState();
    _catalogTabController = TabController(length: 2, vsync: this);
    _mobileTabController = TabController(length: 2, vsync: this);
    _search.text = ref.read(productListProvider).query;
  }

  @override
  void dispose() {
    _catalogTabController.dispose();
    _mobileTabController.dispose();
    _search.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool get _isProductsTab => _catalogTabIndex == 0;

  void _onCatalogTabSelected(int index) {
    if (_catalogTabIndex == index) {
      return;
    }
    setState(() => _catalogTabIndex = index);
    _syncSearchText(index);
  }

  void _syncSearchText(int index) {
    final query = index == 0
        ? ref.read(productListProvider).query
        : ref.read(pdvServiceListProvider).query;
    _search.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  void _onSearchChanged(String value) {
    if (_isProductsTab) {
      ref.read(productListProvider.notifier).onSearchChanged(value);
      return;
    }
    ref.read(pdvServiceListProvider.notifier).onSearchChanged(value);
  }

  void _onCategoryChanged(String? categoriaId) {
    ref.read(productListProvider.notifier).setCategoriaFilter(categoriaId);
  }

  void _addProduct(Product product) {
    ref.read(quotationCartProvider.notifier).addProduct(product);
    PharmaFeedback.success(context, '${product.nomeComercial} adicionado à cotação.');
  }

  void _addService(PdvService service) {
    ref.read(quotationCartProvider.notifier).addService(service);
    PharmaFeedback.success(context, '${service.nome} adicionado à cotação.');
  }

  Future<void> _saveQuotation() async {
    final cart = ref.read(quotationCartProvider);
    if (cart.isEmpty) {
      return;
    }

    final result = await showSaveQuotationDialog(context);
    if (!mounted || result == null) {
      return;
    }

    ref.read(quotationCartProvider.notifier).setSaving(true);
    try {
      final created = await ref.read(quotationRepositoryProvider).createQuotation(
            clienteId: result.clienteId,
            validade: result.validade,
            observacoes: result.observacoes,
            lines: cart.lines,
          );
      ref.read(quotationCartProvider.notifier).clear();
      if (!mounted) {
        return;
      }
      PharmaFeedback.success(
        context,
        'Cotação ${created.numero} guardada — total ${pdvFormatMoney(created.total)}.',
      );
    } on ApiFailure catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.toString());
      }
    } finally {
      ref.read(quotationCartProvider.notifier).setSaving(false);
    }
  }

  Future<void> _onSearchSubmitted({
    required List<Product> products,
    required List<PdvService> services,
    List<Product>? accumulatedProducts,
  }) async {
    if (_isProductsTab) {
      final catalogProducts = accumulatedProducts ?? products;
      if (catalogProducts.isEmpty) {
        return;
      }
      _addProduct(catalogProducts.first);
      ref.read(productListProvider.notifier).onSearchChanged('');
    } else {
      if (services.isEmpty) {
        return;
      }
      _addService(services.first);
      ref.read(pdvServiceListProvider.notifier).onSearchChanged('');
    }
    _search.clear();
    _searchFocusNode.requestFocus();
  }

  Widget _buildCatalogPane({
    required bool isMobile,
    required bool isDesktop,
    required ProductListState productState,
    required ProductListController productController,
    required PdvServiceListState serviceState,
    required PdvServiceListController serviceController,
    required List<Product> displayProducts,
    required bool activeIsLoading,
    required bool activeIsInitialized,
    required bool activeHasItems,
    required String? activeErrorMessage,
    required double bottomPadding,
  }) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    if (activeIsLoading && !activeIsInitialized && !activeHasItems) {
      return const ModuleLoadingState(itemCount: 4);
    }

    if (activeErrorMessage != null && !activeHasItems) {
      return ModuleErrorState(
        title: _isProductsTab ? 'Falha ao carregar produtos' : 'Falha ao carregar serviços',
        message: activeErrorMessage,
        onRetry: _isProductsTab
            ? productController.refreshCurrentPage
            : serviceController.refreshCurrentQuery,
        icon: Icons.error_outline,
      );
    }

    final catalogFooter = _isProductsTab && !isMobile
        ? EnterprisePagination(
            page: productState.page,
            pageSize: productState.pageSize,
            totalCount: productState.totalCount,
            hasMore:
                productState.totalCount == null ? productState.hasMore : null,
            itemsOnPage: productState.items.length,
            isBusy: productState.isLoading,
            itemLabel: 'produtos',
            onPageChanged: productController.goToPage,
            onPageSizeChanged: productController.setPageSize,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activeIsLoading)
          Padding(
            padding: EdgeInsets.only(bottom: s.sm),
            child: LinearProgressIndicator(minHeight: s.xxs),
          ),
        if (activeErrorMessage != null && activeHasItems)
          Padding(
            padding: EdgeInsets.only(bottom: s.sm),
            child: Text(
              activeErrorMessage,
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                    color: t.posDanger,
                  ),
            ),
          ),
        Material(
          color: Colors.transparent,
          child: TabBar(
            controller: _catalogTabController,
            onTap: _onCatalogTabSelected,
            labelColor: t.textPrimary,
            unselectedLabelColor: t.textMuted,
            indicatorColor: t.brandBlue,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Produtos'),
              Tab(text: 'Serviços'),
            ],
          ),
        ),
        SizedBox(height: s.md),
        if (isMobile) ...[
          EnterpriseModuleSearchBar(
            controller: _search,
            focusNode: _searchFocusNode,
            autofocus: true,
            hintText: _isProductsTab
                ? 'Pesquisar produto...'
                : 'Pesquisar serviço...',
            enabled: !activeIsLoading,
            onSubmitted: (_) => _onSearchSubmitted(
              products: productState.items,
              services: serviceState.items,
              accumulatedProducts: displayProducts,
            ),
            onChanged: _onSearchChanged,
          ),
          if (_isProductsTab) ...[
            SizedBox(height: s.sm),
            ProdutoCategoriaFilterDropdown(
              value: productState.categoriaId,
              width: double.infinity,
              enabled: !productState.isLoading,
              onChanged: _onCategoryChanged,
            ),
          ],
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isProductsTab) ...[
                SizedBox(
                  width: 260,
                  child: ProdutoCategoriaFilterDropdown(
                    value: productState.categoriaId,
                    width: 260,
                    enabled: !productState.isLoading,
                    onChanged: _onCategoryChanged,
                  ),
                ),
                SizedBox(width: s.sm),
              ],
              Expanded(
                child: EnterpriseModuleSearchBar(
                  controller: _search,
                  focusNode: _searchFocusNode,
                  maxWidth: 720,
                  hintText: _isProductsTab
                      ? 'Pesquisar por código, nome ou EAN'
                      : 'Pesquisar serviço...',
                  enabled: !activeIsLoading,
                  onSubmitted: (_) => _onSearchSubmitted(
                    products: productState.items,
                    services: serviceState.items,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              if (_isProductsTab) ...[
                SizedBox(width: s.sm),
                IconButton(
                  tooltip: 'Actualizar catálogo',
                  onPressed: productState.isLoading
                      ? null
                      : () => unawaited(
                            productController.refreshCatalogAndPage(),
                          ),
                  icon: Icon(Icons.refresh_rounded, color: t.brandBlue),
                ),
              ],
            ],
          ),
        SizedBox(height: s.md),
        Expanded(
          child: _isProductsTab
              ? isMobile
                  ? PdvProductList(
                      items: displayProducts,
                      query: productState.query,
                      hasMore: productState.hasMore,
                      isLoading: productState.isLoading,
                      canAdd: true,
                      addingProductId: null,
                      onAdd: _addProduct,
                      onLoadMore: () =>
                          productController.goToPage(productState.page + 1),
                      bottomPadding: bottomPadding,
                    )
                  : PdvProductTable(
                      items: productState.items,
                      query: productState.query,
                      canAdd: true,
                      addingProductId: null,
                      onAdd: _addProduct,
                    )
              : isMobile
                  ? PdvServiceList(
                      items: serviceState.items,
                      query: serviceState.query,
                      canAdd: true,
                      onAdd: _addService,
                      bottomPadding: bottomPadding,
                    )
                  : PdvServiceTable(
                      items: serviceState.items,
                      query: serviceState.query,
                      canAdd: true,
                      onAdd: _addService,
                    ),
        ),
        if (!isMobile && catalogFooter != null) ...[
          SizedBox(height: s.sm),
          catalogFooter,
        ],
      ],
    );
  }

  Widget _buildCartPane({required bool compact}) {
    final cartState = ref.watch(quotationCartProvider);
    final controller = ref.read(quotationCartProvider.notifier);
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(s.md, s.md, s.md, s.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Itens da cotação',
                  style: Theme.of(context).textTheme.erpCardTitle.copyWith(
                        color: t.textPrimary,
                      ),
                ),
              ),
              if (!cartState.isEmpty)
                TextButton.icon(
                  onPressed: cartState.isSaving ? null : controller.clear,
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('Limpar'),
                ),
            ],
          ),
        ),
        Expanded(
          child: cartState.isEmpty
              ? const ModuleEmptyState(
                  title: 'Cotação vazia',
                  subtitle:
                      'Pesquise e adicione produtos ou serviços no painel esquerdo.',
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: s.md),
                  itemCount: cartState.lines.length,
                  separatorBuilder: (_, _) => SizedBox(height: s.sm),
                  itemBuilder: (context, index) {
                    final line = cartState.lines[index];
                    return QuotationCartItemCard(
                      key: ValueKey(line.id),
                      line: line,
                      onChanged: controller.updateLine,
                      onIncrement: () => controller.incrementLine(line),
                      onDecrement: () => controller.decrementLine(line),
                      onRemove: () => controller.removeLine(line),
                    );
                  },
                ),
        ),
        QuotationCartSummary(
          itemCount: cartState.itemCount,
          subtotal: cartState.subtotal,
          descontoTotal: cartState.descontoTotal,
          ivaTotal: cartState.ivaTotal,
          total: cartState.total,
          action: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: cartState.isEmpty || cartState.isSaving
                  ? null
                  : () => unawaited(_saveQuotation()),
              icon: cartState.isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: t.bgPrimary,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(compact ? 'Guardar' : 'Guardar cotação'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = w > 1200;
    final isTablet = w > 700 && w <= 1200;
    final isMobile = w <= 700;

    final productState = ref.watch(productListProvider);
    final productController = ref.read(productListProvider.notifier);
    final serviceState = ref.watch(pdvServiceListProvider);
    final serviceController = ref.read(pdvServiceListProvider.notifier);
    final cartState = ref.watch(quotationCartProvider);

    ref.listen<ProductListState>(productListProvider, (prev, next) {
      if (prev?.page != next.page ||
          prev?.query != next.query ||
          prev?.categoriaId != next.categoriaId) {
        if (next.page == 1) {
          _accumulatedProducts = List.of(next.items);
        } else {
          final newItems = next.items
              .where((e) => !_accumulatedProducts.any((a) => a.id == e.id))
              .toList();
          _accumulatedProducts.addAll(newItems);
        }
      } else if (prev?.items != next.items && next.page == 1) {
        _accumulatedProducts = List.of(next.items);
      }
    });

    final displayProducts = isMobile
        ? (_accumulatedProducts.isEmpty ? productState.items : _accumulatedProducts)
        : productState.items;

    final activeIsLoading =
        _isProductsTab ? productState.isLoading : serviceState.isLoading;
    final activeIsInitialized = _isProductsTab
        ? productState.isInitialized
        : serviceState.isInitialized;
    final activeHasItems =
        _isProductsTab ? productState.items.isNotEmpty : serviceState.items.isNotEmpty;
    final activeErrorMessage = _isProductsTab
        ? productState.errorMessage
        : serviceState.errorMessage;

    final catalogPane = _buildCatalogPane(
      isMobile: isMobile,
      isDesktop: isDesktop,
      productState: productState,
      productController: productController,
      serviceState: serviceState,
      serviceController: serviceController,
      displayProducts: displayProducts,
      activeIsLoading: activeIsLoading,
      activeIsInitialized: activeIsInitialized,
      activeHasItems: activeHasItems,
      activeErrorMessage: activeErrorMessage,
      bottomPadding: 0,
    );

    final cartPane = _buildCartPane(compact: isMobile || isTablet);

    if (isMobile) {
      return ColoredBox(
        color: t.bgPrimary,
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: TabBar(
                controller: _mobileTabController,
                labelColor: t.textPrimary,
                unselectedLabelColor: t.textMuted,
                indicatorColor: t.brandBlue,
                tabs: [
                  const Tab(text: 'Catálogo'),
                  Tab(text: 'Cotação (${cartState.itemCount})'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _mobileTabController,
                children: [
                  Padding(
                    padding: EdgeInsets.all(s.md),
                    child: catalogPane,
                  ),
                  cartPane,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ColoredBox(
      color: t.bgPrimary,
      child: Padding(
        padding: EdgeInsets.all(s.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 4, child: catalogPane),
            SizedBox(width: s.lg),
            Expanded(
              flex: 6,
              child: PharmaSurface(
                child: cartPane,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
