import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/feedback/pharma_snackbar.dart';
import '../../../../shared/widgets/layout/module_page_frame.dart';
import '../../../pharmacy/products/domain/entities/product.dart';
import '../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../domain/entities/compra.dart';
import '../providers/compra_provider.dart';

String _formatMoney(num value) => '${value.toStringAsFixed(2)} MT';

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

String _formatIsoDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class PurchasingHubPage extends ConsumerStatefulWidget {
  const PurchasingHubPage({super.key});

  @override
  ConsumerState<PurchasingHubPage> createState() => _PurchasingHubPageState();
}

class _PurchasingHubPageState extends ConsumerState<PurchasingHubPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(purchaseProductListProvider).query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startPurchase() async {
    final fornecedorId = await showDialog<String>(
      context: context,
      builder: (_) => const _FornecedorDialog(),
    );
    if (!mounted || fornecedorId == null) {
      return;
    }
    await ref.read(compraProvider.notifier).startPurchase(fornecedorId);
  }

  Future<void> _handleProduct(Product product) async {
    final compraState = ref.read(compraProvider);
    if (!compraState.canEditActivePurchase) {
      PharmaSnackbar.showError(
        context,
        'Inicie ou seleccione uma compra pendente antes de adicionar itens.',
      );
      return;
    }

    final draft = await showDialog<CompraItemDraft>(
      context: context,
      builder: (_) => _CompraItemDialog(product: product),
    );

    if (!mounted || draft == null) {
      return;
    }

    await ref.read(compraProvider.notifier).addItemToActivePurchase(
          product: product,
          draft: draft,
        );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width <= 920;
    final productState = ref.watch(purchaseProductListProvider);
    final compraState = ref.watch(compraProvider);
    final productController = ref.read(purchaseProductListProvider.notifier);
    final activeProducts = productState.items;

    ref.listen<CompraState>(compraProvider, (previous, next) {
      if (!mounted) {
        return;
      }
      if (previous?.errorMessage != next.errorMessage && next.errorMessage != null) {
        PharmaSnackbar.showError(context, next.errorMessage!);
      }
      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        PharmaSnackbar.showSuccess(context, next.successMessage!);
      }
    });

    return ModulePageFrame(
      actions: [
        OutlinedButton.icon(
          onPressed: ref.read(compraProvider.notifier).refreshLists,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
        FilledButton.icon(
          onPressed: compraState.isCreatingPurchase ? null : _startPurchase,
          icon: compraState.isCreatingPurchase
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_rounded),
          label: const Text('Iniciar Compra'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            SizedBox(
              height: 520,
              child: _LeftPane(
                activeTab: compraState.activeTab,
                productState: productState,
                activeProducts: activeProducts,
                pendingPurchases: compraState.pendingPurchases,
                finalizedPurchases: compraState.finalizedPurchases,
                isLoadingLists: compraState.isLoadingLists,
                activePurchaseId: compraState.activePurchase?.id,
                searchController: _searchController,
                canAddItems: compraState.canEditActivePurchase &&
                    !compraState.isAddingItem &&
                    !compraState.isConfirmingPurchase,
                onSearchChanged: productController.onSearchChanged,
                onRefreshProducts: productController.refreshCurrentPage,
                onGoToPage: productController.goToPage,
                onTabChanged: ref.read(compraProvider.notifier).setActiveTab,
                onSelectProduct: _handleProduct,
                onSelectPendingPurchase:
                    ref.read(compraProvider.notifier).selectPendingPurchase,
                onSelectFinalizedPurchase:
                    ref.read(compraProvider.notifier).selectFinalizedPurchase,
              ),
            ),
            SizedBox(height: s.lg),
            _RightPane(
              state: compraState,
              onConfirm: ref.read(compraProvider.notifier).confirmActivePurchase,
              onRemoveItem:
                  ref.read(compraProvider.notifier).removeItemFromActivePurchase,
            ),
          ] else
            SizedBox(
              height: 760,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _LeftPane(
                      activeTab: compraState.activeTab,
                      productState: productState,
                      activeProducts: activeProducts,
                      pendingPurchases: compraState.pendingPurchases,
                      finalizedPurchases: compraState.finalizedPurchases,
                      isLoadingLists: compraState.isLoadingLists,
                      activePurchaseId: compraState.activePurchase?.id,
                      searchController: _searchController,
                      canAddItems: compraState.canEditActivePurchase &&
                          !compraState.isAddingItem &&
                          !compraState.isConfirmingPurchase,
                      onSearchChanged: productController.onSearchChanged,
                      onRefreshProducts: productController.refreshCurrentPage,
                      onGoToPage: productController.goToPage,
                      onTabChanged: ref.read(compraProvider.notifier).setActiveTab,
                      onSelectProduct: _handleProduct,
                      onSelectPendingPurchase:
                          ref.read(compraProvider.notifier).selectPendingPurchase,
                      onSelectFinalizedPurchase:
                          ref.read(compraProvider.notifier).selectFinalizedPurchase,
                    ),
                  ),
                  SizedBox(width: s.lg),
                  Expanded(
                    flex: 5,
                    child: _RightPane(
                      state: compraState,
                      onConfirm:
                          ref.read(compraProvider.notifier).confirmActivePurchase,
                      onRemoveItem: ref
                          .read(compraProvider.notifier)
                          .removeItemFromActivePurchase,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LeftPane extends StatefulWidget {
  const _LeftPane({
    required this.activeTab,
    required this.productState,
    required this.activeProducts,
    required this.pendingPurchases,
    required this.finalizedPurchases,
    required this.isLoadingLists,
    required this.activePurchaseId,
    required this.searchController,
    required this.canAddItems,
    required this.onSearchChanged,
    required this.onRefreshProducts,
    required this.onGoToPage,
    required this.onTabChanged,
    required this.onSelectProduct,
    required this.onSelectPendingPurchase,
    required this.onSelectFinalizedPurchase,
  });

  final CompraTab activeTab;
  final ProductListState productState;
  final List<Product> activeProducts;
  final List<CompraResumo> pendingPurchases;
  final List<CompraResumo> finalizedPurchases;
  final bool isLoadingLists;
  final String? activePurchaseId;
  final TextEditingController searchController;
  final bool canAddItems;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefreshProducts;
  final Future<void> Function(int page) onGoToPage;
  final ValueChanged<CompraTab> onTabChanged;
  final ValueChanged<Product> onSelectProduct;
  final ValueChanged<String> onSelectPendingPurchase;
  final ValueChanged<String> onSelectFinalizedPurchase;

  @override
  State<_LeftPane> createState() => _LeftPaneState();
}

class _LeftPaneState extends State<_LeftPane> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _indexForTab(widget.activeTab),
    );
  }

  @override
  void didUpdateWidget(_LeftPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _indexForTab(widget.activeTab);
    if (oldWidget.activeTab != widget.activeTab &&
        _tabController.index != nextIndex) {
      _tabController.index = nextIndex;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _indexForTab(CompraTab tab) {
    return switch (tab) {
      CompraTab.produtos => 0,
      CompraTab.pendentes => 1,
      CompraTab.finalizadas => 2,
    };
  }

  CompraTab _tabForIndex(int index) {
    return switch (index) {
      0 => CompraTab.produtos,
      1 => CompraTab.pendentes,
      2 => CompraTab.finalizadas,
      _ => CompraTab.produtos,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: t.card,
          borderRadius: BorderRadius.circular(t.radiusMd),
          child: TabBar(
            controller: _tabController,
            onTap: (index) => widget.onTabChanged(_tabForIndex(index)),
            labelColor: t.textPrimary,
            unselectedLabelColor: t.textMuted,
            indicatorColor: t.brandBlue,
            dividerColor: Colors.transparent,
            tabs: [
              const Tab(text: 'Produtos'),
              Tab(text: 'Pendentes (${widget.pendingPurchases.length})'),
              Tab(text: 'Finalizadas (${widget.finalizedPurchases.length})'),
            ],
          ),
        ),
        SizedBox(height: s.md),
        Expanded(
          child: switch (widget.activeTab) {
            CompraTab.produtos => _ProdutosTab(
                productState: widget.productState,
                activeProducts: widget.activeProducts,
                searchController: widget.searchController,
                canAddItems: widget.canAddItems,
                onSearchChanged: widget.onSearchChanged,
                onRefreshProducts: widget.onRefreshProducts,
                onGoToPage: widget.onGoToPage,
                onSelectProduct: widget.onSelectProduct,
              ),
            CompraTab.pendentes => _ComprasTab(
                title: 'Compras Pendentes',
                subtitle:
                    'Selecione uma compra pendente para carregar os itens e voltar automaticamente para a tab Produtos.',
                isLoading: widget.isLoadingLists,
                purchases: widget.pendingPurchases,
                activePurchaseId: widget.activePurchaseId,
                emptyTitle: 'Nenhuma compra pendente',
                emptySubtitle:
                    'Inicie uma nova compra para criar o registo no backend.',
                onSelect: widget.onSelectPendingPurchase,
              ),
            CompraTab.finalizadas => _ComprasTab(
                title: 'Compras Finalizadas',
                subtitle:
                    'Apenas visualização. Abra um card para consultar a compra no painel da direita.',
                isLoading: widget.isLoadingLists,
                purchases: widget.finalizedPurchases,
                activePurchaseId: widget.activePurchaseId,
                emptyTitle: 'Nenhuma compra finalizada',
                emptySubtitle:
                    'As compras confirmadas aparecerão aqui automaticamente.',
                onSelect: widget.onSelectFinalizedPurchase,
              ),
          },
        ),
      ],
    );
  }
}

class _ProdutosTab extends StatelessWidget {
  const _ProdutosTab({
    required this.productState,
    required this.activeProducts,
    required this.searchController,
    required this.canAddItems,
    required this.onSearchChanged,
    required this.onRefreshProducts,
    required this.onGoToPage,
    required this.onSelectProduct,
  });

  final ProductListState productState;
  final List<Product> activeProducts;
  final TextEditingController searchController;
  final bool canAddItems;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefreshProducts;
  final Future<void> Function(int page) onGoToPage;
  final ValueChanged<Product> onSelectProduct;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Pesquisar produtos (ID, nome, princípio ativo)...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              onPressed: productState.isLoading ? null : onRefreshProducts,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualizar catálogo',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(t.radiusMd),
              borderSide: BorderSide(color: t.border),
            ),
            filled: true,
            fillColor: t.bgPrimary.withValues(alpha: 0.5),
          ),
        ),
        if (productState.isLoading)
          Padding(
            padding: EdgeInsets.only(top: s.sm),
            child: const LinearProgressIndicator(),
          ),
        if (productState.errorMessage != null) ...[
          SizedBox(height: s.sm),
          _InlineBanner(
            message: productState.errorMessage!,
            icon: Icons.error_outline_rounded,
            color: t.posDanger,
          ),
        ],
        SizedBox(height: s.md),
        Expanded(
          child: !productState.isInitialized && productState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : activeProducts.isEmpty
                  ? const _EmptyPane(
                      icon: Icons.inventory_2_outlined,
                      title: 'Nenhum produto ativo encontrado',
                      subtitle:
                          'Ajuste a pesquisa ou atualize o catálogo para tentar novamente.',
                    )
                  : ListView.separated(
                      itemCount: activeProducts.length,
                      separatorBuilder: (_, _) => SizedBox(height: s.sm),
                      itemBuilder: (context, index) {
                        final product = activeProducts[index];
                        return _ProductCard(
                          product: product,
                          enabled: canAddItems,
                          onTap: () => onSelectProduct(product),
                        );
                      },
                    ),
        ),
        if (productState.isInitialized) ...[
          SizedBox(height: s.sm),
          _ProductsPaginationBar(
            page: productState.page,
            pageSize: productState.pageSize,
            itemCount: productState.items.length,
            hasMore: productState.hasMore,
            onPrevious: productState.page > 1 && !productState.isLoading
                ? () => onGoToPage(productState.page - 1)
                : null,
            onNext: productState.hasMore && !productState.isLoading
                ? () => onGoToPage(productState.page + 1)
                : null,
          ),
        ],
      ],
    );
  }
}

class _ComprasTab extends StatelessWidget {
  const _ComprasTab({
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.purchases,
    required this.activePurchaseId,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onSelect,
  });

  final String title;
  final String subtitle;
  final bool isLoading;
  final List<CompraResumo> purchases;
  final String? activePurchaseId;
  final String emptyTitle;
  final String emptySubtitle;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: t.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        SizedBox(height: s.xs),
        Text(subtitle, style: TextStyle(color: t.textMuted)),
        SizedBox(height: s.sm),
        if (isLoading) const LinearProgressIndicator(),
        SizedBox(height: s.sm),
        Expanded(
          child: purchases.isEmpty
              ? _EmptyPane(
                  icon: Icons.assignment_outlined,
                  title: emptyTitle,
                  subtitle: emptySubtitle,
                )
              : ListView.separated(
                  itemCount: purchases.length,
                  separatorBuilder: (_, _) => SizedBox(height: s.sm),
                  itemBuilder: (context, index) {
                    final purchase = purchases[index];
                    return _CompraResumoCard(
                      purchase: purchase,
                      selected: purchase.id == activePurchaseId,
                      onTap: () => onSelect(purchase.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.enabled,
    required this.onTap,
  });

  final Product product;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: Container(
        padding: EdgeInsets.all(s.md),
        decoration: BoxDecoration(
          color: t.bgPrimary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(t.radiusMd),
          border: Border.all(color: enabled ? t.border : t.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nome,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (product.substanciaActiva != null || product.dosagem != null)
                    Padding(
                      padding: EdgeInsets.only(top: s.xs),
                      child: Text(
                        [
                          product.substanciaActiva,
                          product.dosagem,
                          product.apresentacao,
                        ].whereType<String>().where((value) => value.isNotEmpty).join(' • '),
                        style: TextStyle(color: t.textMuted, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: s.sm),
            Text(
              _formatMoney(product.precoVenda),
              style: TextStyle(
                color: t.brandGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: s.md),
            IconButton(
              onPressed: enabled ? onTap : null,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              style: IconButton.styleFrom(
                backgroundColor: t.brandBlue.withValues(alpha: 0.1),
                foregroundColor: t.brandBlue,
              ),
              tooltip: 'Adicionar à compra',
            ),
          ],
        ),
      ),
    );
  }
}

class _CompraResumoCard extends StatelessWidget {
  const _CompraResumoCard({
    required this.purchase,
    required this.selected,
    required this.onTap,
  });

  final CompraResumo purchase;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isFinalized = purchase.status == CompraStatus.recebida;
    final accent = purchase.status.isEditable ? t.posWarning : t.brandGreen;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: Container(
        padding: EdgeInsets.all(s.md),
        decoration: BoxDecoration(
          color: selected ? t.brandBlue.withValues(alpha: 0.08) : t.bgPrimary,
          borderRadius: BorderRadius.circular(t.radiusMd),
          border: Border.all(
            color: selected ? t.brandBlue.withValues(alpha: 0.4) : t.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compra ${purchase.id}',
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Fornecedor: ${purchase.fornecedorNome}',
                        style: TextStyle(color: t.textMuted),
                      ),
                    ],
                  ),
                ),
                _InfoTag(label: purchase.status.label, color: accent),
              ],
            ),
            SizedBox(height: s.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data: ${_formatDate(purchase.data)}',
                        style: TextStyle(color: t.textMuted)),
                    Text('Itens: ${purchase.totalItens}',
                        style: TextStyle(color: t.textMuted)),
                  ],
                ),
                if (isFinalized)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.print_outlined, size: 20),
                        onPressed: () {},
                        tooltip: 'Imprimir compra',
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 20),
                        onPressed: onTap,
                        tooltip: 'Ver detalhes',
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RightPane extends StatelessWidget {
  const _RightPane({
    required this.state,
    required this.onConfirm,
    required this.onRemoveItem,
  });

  final CompraState state;
  final Future<void> Function() onConfirm;
  final Future<void> Function(String itemId) onRemoveItem;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final activePurchase = state.activePurchase;

    return Container(
      padding: EdgeInsets.all(s.lg),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  activePurchase == null ? 'Nova Compra' : 'Compra #${activePurchase.id}',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              if (state.isLoadingActivePurchase ||
                  state.isAddingItem ||
                  state.isConfirmingPurchase)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          SizedBox(height: s.lg),
          if (activePurchase == null)
            const Expanded(
              child: _EmptyPane(
                icon: Icons.shopping_cart_outlined,
                title: 'Nenhuma compra ativa',
                subtitle: 'Inicie uma compra para adicionar produtos.',
              ),
            )
          else ...[
            _ActivePurchaseHeader(purchase: activePurchase),
            SizedBox(height: s.md),
            Expanded(
              child: activePurchase.items.isEmpty
                  ? const _EmptyPane(
                      icon: Icons.playlist_add_outlined,
                      title: 'Carrinho vazio',
                      subtitle: 'Selecione produtos na lista ao lado.',
                    )
                  : _PurchaseItemsTable(
                      items: activePurchase.items,
                      isEditable: activePurchase.status.isEditable,
                      onRemove: onRemoveItem,
                    ),
            ),
          ],
          SizedBox(height: s.md),
          _ConfirmFooter(
            canConfirm: state.canConfirmActivePurchase,
            isLoading: state.isConfirmingPurchase,
            activePurchase: activePurchase,
            onConfirm: onConfirm,
          ),
        ],
      ),
    );
  }
}

class _PurchaseItemsTable extends StatelessWidget {
  const _PurchaseItemsTable({
    required this.items,
    required this.isEditable,
    required this.onRemove,
  });

  final List<CompraItem> items;
  final bool isEditable;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(t.bgPrimary.withValues(alpha: 0.1)),
          columnSpacing: s.lg,
          columns: const [
            DataColumn(label: Text('Produto')),
            DataColumn(label: Text('Lote')),
            DataColumn(label: Text('Preço Compra')),
            DataColumn(label: Text('Preço Venda')),
            DataColumn(label: Text('Validade')),
            DataColumn(label: Text('Qtd')),
            DataColumn(label: Text('Subtotal')),
            DataColumn(label: Text('Ações')),
          ],
          rows: items.map((item) {
            return DataRow(
              cells: [
                DataCell(Text(item.produtoNome)),
                DataCell(Text(item.numeroLote)),
                DataCell(Text(_formatMoney(item.precoCompra))),
                DataCell(Text(item.precoVenda != null ? _formatMoney(item.precoVenda!) : '-')),
                DataCell(Text(item.dataValidade)),
                DataCell(Text(item.quantidade.toStringAsFixed(0))),
                DataCell(Text(_formatMoney(item.subtotal))),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: isEditable ? () {} : null,
                        tooltip: 'Editar item',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        onPressed: isEditable ? () => onRemove(item.id) : null,
                        color: t.posDanger,
                        tooltip: 'Remover item',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ActivePurchaseHeader extends StatelessWidget {
  const _ActivePurchaseHeader({required this.purchase});

  final CompraDetalhe purchase;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.bgPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ID ${purchase.id}',
            style: TextStyle(
              color: t.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: s.sm),
          Wrap(
            spacing: s.sm,
            runSpacing: s.sm,
            children: [
              _InfoTag(label: purchase.status.label, color: purchase.status.isEditable ? t.posWarning : t.brandGreen),
              _InfoTag(label: 'Fornecedor ${purchase.fornecedorId}', color: t.brandBlue),
              _InfoTag(label: 'Data ${_formatDate(purchase.data)}', color: t.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmFooter extends StatelessWidget {
  const _ConfirmFooter({
    required this.canConfirm,
    required this.isLoading,
    required this.activePurchase,
    required this.onConfirm,
  });

  final bool canConfirm;
  final bool isLoading;
  final CompraDetalhe? activePurchase;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final helperText = switch (activePurchase?.status) {
      null => 'Inicie uma compra para habilitar ações.',
      CompraStatus.pendente => activePurchase!.items.isEmpty
          ? 'Adicione itens para confirmar.'
          : 'Total: ${_formatMoney(activePurchase!.total)}',
      CompraStatus.recebida => 'Compra finalizada.',
      CompraStatus.cancelada => 'Compra cancelada.',
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: BorderRadius.circular(t.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            helperText,
            style: TextStyle(
              color: activePurchase?.status == CompraStatus.pendente &&
                      activePurchase!.items.isNotEmpty
                  ? t.textPrimary
                  : t.textMuted,
              fontWeight: activePurchase?.status == CompraStatus.pendente &&
                      activePurchase!.items.isNotEmpty
                  ? FontWeight.w700
                  : FontWeight.normal,
            ),
          ),
          SizedBox(height: s.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: activePurchase != null ? () {} : null,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Imprimir'),
                ),
              ),
              SizedBox(width: s.md),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: canConfirm ? onConfirm : null,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(isLoading ? 'A confirmar...' : 'Confirmar Compra'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(t.radiusMd),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: t.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: s.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: t.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPane extends StatelessWidget {
  const _EmptyPane({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(s.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: t.textMuted),
            SizedBox(height: s.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: s.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FornecedorDialog extends ConsumerStatefulWidget {
  const _FornecedorDialog();

  @override
  ConsumerState<_FornecedorDialog> createState() => _FornecedorDialogState();
}

class _FornecedorDialogState extends ConsumerState<_FornecedorDialog> {
  String? _selectedId;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(supplierListProvider);
    final s = context.spacing;

    return AlertDialog(
      title: const Text('Selecionar fornecedor'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Pesquisar fornecedor',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
            SizedBox(height: s.md),
            Expanded(
              child: suppliersAsync.when(
                data: (suppliers) {
                  final filtered = suppliers
                      .where((s) =>
                          s.nome.toLowerCase().contains(_search.toLowerCase()) ||
                          s.id.toLowerCase().contains(_search.toLowerCase()))
                      .toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('Nenhum fornecedor encontrado'));
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final supplier = filtered[index];
                      final isSelected = _selectedId == supplier.id;

                      return ListTile(
                        selected: isSelected,
                        title: Text(supplier.nome),
                        subtitle: Text('ID: ${supplier.id}'),
                        onTap: () => setState(() => _selectedId = supplier.id),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Erro: $err')),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _selectedId == null
              ? null
              : () => Navigator.of(context).pop(_selectedId),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Iniciar compra'),
        ),
      ],
    );
  }
}

class _CompraItemDialog extends StatefulWidget {
  const _CompraItemDialog({required this.product});

  final Product product;

  @override
  State<_CompraItemDialog> createState() => _CompraItemDialogState();
}

class _CompraItemDialogState extends State<_CompraItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _loteController;
  late final TextEditingController _precoCompraController;
  late final TextEditingController _precoVendaController;
  late final TextEditingController _dataValidadeController;
  late final TextEditingController _quantidadeController;

  @override
  void initState() {
    super.initState();
    _loteController = TextEditingController(text: widget.product.lote ?? '');
    _precoCompraController = TextEditingController();
    _precoVendaController = TextEditingController(
      text: widget.product.precoVenda > 0
          ? widget.product.precoVenda.toStringAsFixed(2)
          : '',
    );
    _dataValidadeController = TextEditingController(
      text: widget.product.dataValidade != null
          ? _formatIsoDate(widget.product.dataValidade!)
          : '2027-12-31',
    );
    _quantidadeController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _loteController.dispose();
    _precoCompraController.dispose();
    _precoVendaController.dispose();
    _dataValidadeController.dispose();
    _quantidadeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    Navigator.of(context).pop(
      CompraItemDraft(
        product: widget.product,
        numeroLote: _loteController.text.trim(),
        dataValidade: _dataValidadeController.text.trim(),
        quantidade: _parseNumber(_quantidadeController.text),
        precoCompra: _parseNumber(_precoCompraController.text),
        precoVenda: _precoVendaController.text.trim().isEmpty
            ? null
            : _parseNumber(_precoVendaController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return AlertDialog(
      title: Text('Adicionar ${widget.product.nome}'),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: s.md,
              runSpacing: s.md,
              children: [
                _DialogField(
                  controller: _loteController,
                  label: 'Lote',
                  hint: 'Ex.: LOTE-2026-001',
                  validator: _requiredValidator,
                ),
                _DialogField(
                  controller: _precoCompraController,
                  label: 'Preço de compra',
                  hint: 'Ex.: 44.10',
                  validator: _positiveNumberValidator,
                ),
                _DialogField(
                  controller: _precoVendaController,
                  label: 'Preço de venda',
                  hint: 'Opcional',
                  validator: _optionalPositiveNumberValidator,
                ),
                _DialogField(
                  controller: _dataValidadeController,
                  label: 'Data de validade',
                  hint: 'AAAA-MM-DD',
                  validator: _dateValidator,
                ),
                _DialogField(
                  controller: _quantidadeController,
                  label: 'Quantidade',
                  hint: 'Ex.: 10',
                  validator: _positiveNumberValidator,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('Adicionar item'),
        ),
      ],
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }
    return null;
  }

  String? _dateValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Campo obrigatorio';
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(normalized)) {
      return 'Use o formato AAAA-MM-DD';
    }
    return null;
  }

  String? _positiveNumberValidator(String? value) {
    final normalized = value?.trim().replaceAll(',', '.') ?? '';
    if (normalized.isEmpty) {
      return 'Campo obrigatorio';
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return 'Informe um numero maior que zero';
    }
    return null;
  }

  String? _optionalPositiveNumberValidator(String? value) {
    final normalized = value?.trim().replaceAll(',', '.') ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0) {
      return 'Informe um numero valido';
    }
    return null;
  }

  double _parseNumber(String value) {
    return double.parse(value.trim().replaceAll(',', '.'));
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _ProductsPaginationBar extends StatelessWidget {
  const _ProductsPaginationBar({
    required this.page,
    required this.pageSize,
    required this.itemCount,
    required this.hasMore,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int pageSize;
  final int itemCount;
  final bool hasMore;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isMobile = MediaQuery.sizeOf(context).width <= 700;
    final start = itemCount == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final end = itemCount == 0 ? 0 : start + itemCount - 1;
    final resultsLabel = itemCount == 0
        ? 'Sem resultados nesta página'
        : 'Mostrando $start-$end';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.5)),
      ),
      child: isMobile
          ? Row(
              children: [
                OutlinedButton(
                  onPressed: onPrevious,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(t.minTouchTarget, t.minTouchTarget),
                    padding: EdgeInsets.symmetric(horizontal: s.sm),
                  ),
                  child: Icon(Icons.chevron_left_rounded, size: t.iconSm),
                ),
                SizedBox(width: s.sm),
                Expanded(
                  child: Text(
                    '$resultsLabel • Página $page',
                    style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: s.sm),
                FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(t.minTouchTarget, t.minTouchTarget),
                    padding: EdgeInsets.symmetric(horizontal: s.sm),
                  ),
                  child: Icon(Icons.chevron_right_rounded, size: t.iconSm),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  resultsLabel,
                  style: TextStyle(color: t.textMuted),
                ),
                SizedBox(height: s.sm),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onPrevious,
                      icon: const Icon(Icons.chevron_left_rounded),
                      label: const Text('Anterior'),
                    ),
                    SizedBox(width: s.sm),
                    Text(
                      'Página $page',
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.chevron_right_rounded),
                      label: Text(hasMore ? 'Próxima' : 'Fim'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
