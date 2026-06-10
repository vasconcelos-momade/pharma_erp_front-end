import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

String _formatQuantity(num value) {
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

String _formatDisplayDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  return _formatDate(parsed);
}

String _formatIsoDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

DateTime? _parseDateInputValue(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(normalized);
  if (parsed != null) {
    return parsed;
  }

  final match = RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch(normalized);
  if (match != null) {
    return DateTime.tryParse(match.group(0)!);
  }

  final displayMatch = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(normalized);
  if (displayMatch != null) {
    final day = int.tryParse(displayMatch.group(1)!);
    final month = int.tryParse(displayMatch.group(2)!);
    final year = int.tryParse(displayMatch.group(3)!);
    if (day != null && month != null && year != null) {
      final parsed = DateTime(year, month, day);
      if (parsed.year == year && parsed.month == month && parsed.day == day) {
        return parsed;
      }
    }
  }

  return null;
}

String _normalizeDateInputValue(String? value) {
  final parsed = _parseDateInputValue(value);
  if (parsed == null) {
    return value?.trim() ?? '';
  }
  return _formatDate(parsed);
}

class _DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;
    final formatted = _formatDigits(limitedDigits);
    final digitsBeforeCursor = _countDigitsBeforeCursor(newValue);
    final selectionOffset = _selectionOffsetForDigits(
      formatted,
      digitsBeforeCursor.clamp(0, limitedDigits.length),
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
      composing: TextRange.empty,
    );
  }

  int _countDigitsBeforeCursor(TextEditingValue value) {
    final cursor = value.selection.baseOffset.clamp(0, value.text.length);
    return RegExp(r'\d').allMatches(value.text.substring(0, cursor)).length;
  }

  int _selectionOffsetForDigits(String formatted, int digitsBeforeCursor) {
    if (digitsBeforeCursor <= 0) {
      return 0;
    }

    var seenDigits = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        seenDigits++;
        if (seenDigits == digitsBeforeCursor) {
          return i + 1;
        }
      }
    }

    return formatted.length;
  }

  String _formatDigits(String digits) {
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if ((i == 2 || i == 4) && buffer.isNotEmpty) {
        buffer.write('/');
      }
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }
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
    final result = await showDialog<NovaCompraDialogResult>(
      context: context,
      builder: (_) => const _NovaCompraDialog(),
    );
    if (!mounted || result == null) {
      return;
    }
    await ref.read(compraProvider.notifier).startPurchase(
          fornecedorId: result.fornecedorId,
          numeroDocumento: result.numeroDocumento,
        );
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
          draft: draft,
        );
  }

  Future<void> _handleEditPurchaseItem(CompraItem item) async {
    final compraState = ref.read(compraProvider);
    if (!compraState.canEditActivePurchase) {
      PharmaSnackbar.showError(
        context,
        'Seleccione uma compra pendente antes de editar itens.',
      );
      return;
    }

    final draft = await showDialog<CompraItemDraft>(
      context: context,
      builder: (_) => _CompraItemDialog(item: item),
    );

    if (!mounted || draft == null) {
      return;
    }

    await ref.read(compraProvider.notifier).updateItemInActivePurchase(
          item: item,
          draft: draft,
        );
  }

  Future<void> _confirmRemovePurchaseItem(CompraItem item) async {
    final t = context.pharmaTokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar remoção'),
        content: Text(
          'Deseja remover o item "${item.produtoNome}" da compra?\n\n'
          'Lote: ${item.numeroLote.isNotEmpty ? item.numeroLote : '—'}\n'
          'Quantidade: ${item.quantidade.toStringAsFixed(item.quantidade.truncateToDouble() == item.quantidade ? 0 : 2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: t.posDanger),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await ref.read(compraProvider.notifier).removeItemFromActivePurchase(item.id);
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
              onEditItem: _handleEditPurchaseItem,
              onRemoveItem: _confirmRemovePurchaseItem,
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
                      onEditItem: _handleEditPurchaseItem,
                      onRemoveItem: _confirmRemovePurchaseItem,
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
    final statusLabel = product.ativo ? 'Activo' : 'Inactivo';
    final productDetails = [
      product.substanciaActiva,
      product.dosagem,
      [product.forma, product.apresentacao]
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .join(' / '),
    ]
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .join(' • ');

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
                  if (productDetails.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: s.xs),
                      child: Text(
                        productDetails,
                        style: TextStyle(color: t.textMuted, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: s.md),
            _InfoTag(
              label: statusLabel,
              color: product.ativo ? t.brandGreen : t.textMuted,
            ),
            SizedBox(width: s.sm),
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
                        purchase.numeroDocumento.isNotEmpty
                            ? 'Doc. ${purchase.numeroDocumento}'
                            : 'Compra ${purchase.id}',
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Fornecedor: ${purchase.fornecedorNome}',
                        style: TextStyle(color: t.textMuted),
                      ),
                      if (purchase.numeroDocumento.isNotEmpty)
                        Text(
                          'ID interno: ${purchase.id}',
                          style: TextStyle(color: t.textMuted, fontSize: 12),
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
    required this.onEditItem,
    required this.onRemoveItem,
  });

  final CompraState state;
  final Future<void> Function() onConfirm;
  final Future<void> Function(CompraItem item) onEditItem;
  final Future<void> Function(CompraItem item) onRemoveItem;

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
                      onEdit: onEditItem,
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
    required this.onEdit,
    required this.onRemove,
  });

  final List<CompraItem> items;
  final bool isEditable;
  final ValueChanged<CompraItem> onEdit;
  final ValueChanged<CompraItem> onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 768) {
          return _PurchaseItemsCardList(
            items: items,
            isEditable: isEditable,
            onEdit: onEdit,
            onRemove: onRemove,
          );
        }

        if (width < 1200) {
          return _PurchaseItemsTabletTable(
            items: items,
            isEditable: isEditable,
            onEdit: onEdit,
            onRemove: onRemove,
          );
        }

        return _PurchaseItemsDesktopTable(
          items: items,
          isEditable: isEditable,
          onEdit: onEdit,
          onRemove: onRemove,
        );
      },
    );
  }
}

class _PurchaseItemsDesktopTable extends StatelessWidget {
  const _PurchaseItemsDesktopTable({
    required this.items,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
  });

  final List<CompraItem> items;
  final bool isEditable;
  final ValueChanged<CompraItem> onEdit;
  final ValueChanged<CompraItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1200,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                t.bgPrimary.withValues(alpha: 0.1),
              ),
              columnSpacing: s.lg,
              columns: const [
                DataColumn(label: Text('Produto')),
                DataColumn(label: Text('Lote')),
                DataColumn(label: Text('Validade')),
                DataColumn(label: Text('Preço Compra')),
                DataColumn(label: Text('Preço Venda')),
                DataColumn(label: Text('Qtd')),
                DataColumn(label: Text('Subtotal')),
                DataColumn(label: Text('Ações')),
              ],
              rows: items.map((item) {
                return DataRow(
                  cells: [
                    DataCell(SizedBox(width: 260, child: Text(item.produtoNome))),
                    DataCell(SizedBox(width: 150, child: Text(item.numeroLote))),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(_formatDisplayDate(item.dataValidade)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(_formatMoney(item.precoCompra)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(
                          item.precoVenda != null
                              ? _formatMoney(item.precoVenda!)
                              : '-',
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 90,
                        child: Text(_formatQuantity(item.quantidade)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(_formatMoney(item.subtotal)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: _PurchaseItemActionButtons(
                          item: item,
                          isEditable: isEditable,
                          onEdit: onEdit,
                          onRemove: onRemove,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseItemsTabletTable extends StatelessWidget {
  const _PurchaseItemsTabletTable({
    required this.items,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
  });

  final List<CompraItem> items;
  final bool isEditable;
  final ValueChanged<CompraItem> onEdit;
  final ValueChanged<CompraItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 920,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                t.bgPrimary.withValues(alpha: 0.1),
              ),
              columnSpacing: s.md,
              columns: const [
                DataColumn(label: Text('Produto')),
                DataColumn(label: Text('Lote')),
                DataColumn(label: Text('Preço Compra')),
                DataColumn(label: Text('Qtd')),
                DataColumn(label: Text('Subtotal')),
                DataColumn(label: Text('Ações')),
              ],
              rows: items.map((item) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 260,
                        child: Tooltip(
                          message:
                              'Validade: ${_formatDisplayDate(item.dataValidade)}\n'
                              'Preço venda: ${item.precoVenda != null ? _formatMoney(item.precoVenda!) : '-'}',
                          child: Text(
                            item.produtoNome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(width: 140, child: Text(item.numeroLote)),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(_formatMoney(item.precoCompra)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 80,
                        child: Text(_formatQuantity(item.quantidade)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(_formatMoney(item.subtotal)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 170,
                        child: _PurchaseItemActionButtons(
                          item: item,
                          isEditable: isEditable,
                          onEdit: onEdit,
                          onRemove: onRemove,
                          showDetailsButton: true,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseItemsCardList extends StatelessWidget {
  const _PurchaseItemsCardList({
    required this.items,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
  });

  final List<CompraItem> items;
  final bool isEditable;
  final ValueChanged<CompraItem> onEdit;
  final ValueChanged<CompraItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        return _PurchaseItemCard(
          item: item,
          isEditable: isEditable,
          onEdit: onEdit,
          onRemove: onRemove,
        );
      },
    );
  }
}

class _PurchaseItemCard extends StatelessWidget {
  const _PurchaseItemCard({
    required this.item,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
  });

  final CompraItem item;
  final bool isEditable;
  final ValueChanged<CompraItem> onEdit;
  final ValueChanged<CompraItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Container(
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.bgPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.produtoNome,
            style: TextStyle(
              color: t.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: s.sm),
          Wrap(
            spacing: s.md,
            runSpacing: s.sm,
            children: [
              _PurchaseItemInfo(label: 'Lote', value: item.numeroLote),
              _PurchaseItemInfo(
                label: 'Validade',
                value: _formatDisplayDate(item.dataValidade),
              ),
              _PurchaseItemInfo(
                label: 'Preço compra',
                value: _formatMoney(item.precoCompra),
              ),
              _PurchaseItemInfo(
                label: 'Preço venda',
                value: item.precoVenda != null
                    ? _formatMoney(item.precoVenda!)
                    : '-',
              ),
              _PurchaseItemInfo(
                label: 'Quantidade',
                value: _formatQuantity(item.quantidade),
              ),
              _PurchaseItemInfo(
                label: 'Subtotal',
                value: _formatMoney(item.subtotal),
              ),
            ],
          ),
          SizedBox(height: s.md),
          Wrap(
            spacing: s.sm,
            runSpacing: s.sm,
            children: [
              OutlinedButton.icon(
                onPressed: isEditable ? () => onEdit(item) : null,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
              OutlinedButton.icon(
                onPressed: isEditable ? () => onRemove(item) : null,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remover'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: t.posDanger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchaseItemInfo extends StatelessWidget {
  const _PurchaseItemInfo({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: t.textMuted,
          fontSize: 12,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: t.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _PurchaseItemActionButtons extends StatelessWidget {
  const _PurchaseItemActionButtons({
    required this.item,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
    this.showDetailsButton = false,
  });

  final CompraItem item;
  final bool isEditable;
  final ValueChanged<CompraItem> onEdit;
  final ValueChanged<CompraItem> onRemove;
  final bool showDetailsButton;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDetailsButton)
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            onPressed: () => _showPurchaseItemDetails(context, item),
            tooltip: 'Ver detalhes',
          ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: isEditable ? () => onEdit(item) : null,
          tooltip: 'Editar item',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          onPressed: isEditable ? () => onRemove(item) : null,
          color: t.posDanger,
          tooltip: 'Remover item',
        ),
      ],
    );
  }
}

Future<void> _showPurchaseItemDetails(BuildContext context, CompraItem item) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final s = dialogContext.spacing;

      return AlertDialog(
        title: Text(item.produtoNome),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogDetailRow(label: 'Lote', value: item.numeroLote),
              SizedBox(height: s.sm),
              _DialogDetailRow(
                label: 'Validade',
                value: _formatDisplayDate(item.dataValidade),
              ),
              SizedBox(height: s.sm),
              _DialogDetailRow(
                label: 'Preço compra',
                value: _formatMoney(item.precoCompra),
              ),
              SizedBox(height: s.sm),
              _DialogDetailRow(
                label: 'Preço venda',
                value: item.precoVenda != null
                    ? _formatMoney(item.precoVenda!)
                    : '-',
              ),
              SizedBox(height: s.sm),
              _DialogDetailRow(
                label: 'Quantidade',
                value: _formatQuantity(item.quantidade),
              ),
              SizedBox(height: s.sm),
              _DialogDetailRow(
                label: 'Subtotal',
                value: _formatMoney(item.subtotal),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
    },
  );
}

class _DialogDetailRow extends StatelessWidget {
  const _DialogDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: t.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: t.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
            purchase.numeroDocumento.isNotEmpty
                ? 'Documento ${purchase.numeroDocumento}'
                : 'Compra #${purchase.id}',
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
              if (purchase.numeroDocumento.isNotEmpty)
                _InfoTag(label: 'Nº doc. ${purchase.numeroDocumento}', color: t.brandBlue),
              _InfoTag(label: 'Fornecedor ${purchase.fornecedorNome}', color: t.brandBlue),
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

class NovaCompraDialogResult {
  const NovaCompraDialogResult({
    required this.fornecedorId,
    required this.numeroDocumento,
  });

  final String fornecedorId;
  final String numeroDocumento;
}

class _NovaCompraDialog extends ConsumerStatefulWidget {
  const _NovaCompraDialog();

  @override
  ConsumerState<_NovaCompraDialog> createState() => _NovaCompraDialogState();
}

class _NovaCompraDialogState extends ConsumerState<_NovaCompraDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numeroDocumentoController = TextEditingController();
  String? _selectedId;
  String _search = '';

  @override
  void dispose() {
    _numeroDocumentoController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final numeroDocumento = _numeroDocumentoController.text.trim();
    return _selectedId != null && numeroDocumento.isNotEmpty;
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true || !_canSubmit) {
      return;
    }
    Navigator.of(context).pop(
      NovaCompraDialogResult(
        fornecedorId: _selectedId!,
        numeroDocumento: _numeroDocumentoController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(supplierListProvider);
    final s = context.spacing;

    return AlertDialog(
      title: const Text('Nova Compra'),
      content: SizedBox(
        width: 400,
        height: 560,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _numeroDocumentoController,
                decoration: const InputDecoration(
                  labelText: 'Número do Documento *',
                  hintText: 'Ex.: FT-2026/00123',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o número do documento';
                  }
                  return null;
                },
              ),
              SizedBox(height: s.md),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _canSubmit ? _submit : null,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Iniciar compra'),
        ),
      ],
    );
  }
}

class _CompraItemDialog extends StatefulWidget {
  const _CompraItemDialog({
    this.product,
    this.item,
  }) : assert(product != null || item != null);

  final Product? product;
  final CompraItem? item;

  bool get isEditing => item != null;
  String get productName => item?.produtoNome ?? product!.nome;
  String get productId => item?.produtoId ?? product!.id;

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
    _loteController = TextEditingController(
      text: widget.item?.numeroLote ?? widget.product?.lote ?? '',
    );
    _precoCompraController = TextEditingController(
      text: widget.item != null
          ? widget.item!.precoCompra.toStringAsFixed(2)
          : '',
    );
    _precoVendaController = TextEditingController(
      text: widget.item?.precoVenda != null
          ? widget.item!.precoVenda!.toStringAsFixed(2)
          : '',
    );
    _dataValidadeController = TextEditingController(
      text: widget.item != null
          ? _normalizeDateInputValue(widget.item!.dataValidade)
          : (widget.product?.dataValidade != null
                ? _formatDate(widget.product!.dataValidade!)
                : _formatDate(DateTime(2027, 12, 31))),
    );
    _quantidadeController = TextEditingController(
      text: widget.item != null
          ? _formatQuantity(widget.item!.quantidade)
          : '1',
    );
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
        produtoId: widget.productId,
        produtoNome: widget.productName,
        numeroLote: _loteController.text.trim(),
        dataValidade: _formatIsoDate(
          _parseDateInputValue(_dataValidadeController.text.trim())!,
        ),
        quantidade: _parseNumber(_quantidadeController.text),
        precoCompra: _parseNumber(_precoCompraController.text),
        precoVenda: _precoVendaController.text.trim().isEmpty
            ? null
            : _parseNumber(_precoVendaController.text),
      ),
    );
  }

  Future<void> _pickExpiryDate() async {
    final initialDate =
        _parseDateInputValue(_dataValidadeController.text.trim()) ??
        widget.product?.dataValidade ??
        DateTime.now().add(const Duration(days: 365));
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );
    if (pickedDate == null) {
      return;
    }
    _dataValidadeController.text = _formatDate(pickedDate);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return AlertDialog(
      title: Text(
        widget.isEditing
            ? 'Editar ${widget.productName}'
            : 'Adicionar ${widget.productName}',
      ),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DialogField(
                  controller: _loteController,
                  label: 'Lote',
                  hint: 'Ex.: LOTE-2026-001',
                  validator: _requiredValidator,
                ),
                SizedBox(height: s.md),
                _DialogField(
                  controller: _dataValidadeController,
                  label: 'Data de validade',
                  hint: 'DD/MM/AAAA',
                  validator: _dateValidator,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    _DateTextInputFormatter(),
                  ],
                  onEditingComplete: () {
                    _dataValidadeController.text = _normalizeDateInputValue(
                      _dataValidadeController.text,
                    );
                  },
                  suffixIcon: IconButton(
                    onPressed: _pickExpiryDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    tooltip: 'Selecionar data',
                  ),
                ),
                SizedBox(height: s.md),
                _DialogField(
                  controller: _precoCompraController,
                  label: 'Preço de compra',
                  hint: 'Ex.: 44.10',
                  validator: _positiveNumberValidator,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: s.md),
                _DialogField(
                  controller: _precoVendaController,
                  label: 'Preço de venda',
                  hint: 'Opcional',
                  validator: _optionalPositiveNumberValidator,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: s.md),
                _DialogField(
                  controller: _quantidadeController,
                  label: 'Quantidade',
                  hint: 'Ex.: 10',
                  validator: _positiveNumberValidator,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          icon: Icon(
            widget.isEditing ? Icons.save_outlined : Icons.add_task_rounded,
          ),
          label: Text(widget.isEditing ? 'Guardar alterações' : 'Adicionar item'),
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
    if (_parseDateInputValue(normalized) == null) {
      return 'Use o formato DD/MM/AAAA';
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
    this.keyboardType,
    this.inputFormatters,
    this.onEditingComplete,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onEditingComplete;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onEditingComplete: onEditingComplete,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
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
