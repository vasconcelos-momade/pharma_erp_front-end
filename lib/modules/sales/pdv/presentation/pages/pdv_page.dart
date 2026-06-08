import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/widgets/feedback/pharma_snackbar.dart';
import '../../../../pharmacy/products/domain/entities/product.dart';
import '../../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../../invoices/presentation/providers/invoice_action_provider.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../domain/entities/pdv_cart_line.dart';
import '../../domain/entities/pdv_checkout.dart';
import '../../domain/entities/pdv_service.dart';
import '../providers/caixa_sessao_provider.dart';
import '../providers/pdv_cart_provider.dart';
import '../providers/pdv_service_provider.dart';
import '../widgets/abrir_caixa_dialog.dart';
import '../widgets/finalizar_venda_dialog.dart';

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatMoney(num value) {
  final amount = value.toDouble();
  final hasDecimals = amount != amount.truncateToDouble();
  return '${amount.toStringAsFixed(hasDecimals ? 2 : 0)} MT';
}

class PdvPage extends ConsumerStatefulWidget {
  const PdvPage({super.key});

  @override
  ConsumerState<PdvPage> createState() => _PdvPageState();
}

class _PdvPageState extends ConsumerState<PdvPage>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  final _searchFocusNode = FocusNode();
  late final TabController _catalogTabController;
  int _catalogTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _catalogTabController = TabController(length: 2, vsync: this);
    _search.text = ref.read(productListProvider).query;
  }

  @override
  void dispose() {
    _catalogTabController.dispose();
    _search.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool get _isProductsTab => _catalogTabIndex == 0;

  void _onCatalogTabSelected(int index) {
    if (_catalogTabIndex == index) {
      return;
    }
    setState(() {
      _catalogTabIndex = index;
    });
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

  Future<void> _openAbrirCaixaDialog() {
    return showAbrirCaixaDialog(context);
  }

  bool _ensureCaixaAberto() {
    if (ref.read(caixaSessaoProvider).hasSessaoAberta) {
      return true;
    }
    unawaited(_openAbrirCaixaDialog());
    return false;
  }

  Future<void> _onSearchSubmitted({
    required List<Product> products,
    required List<PdvService> services,
  }) async {
    if (!_ensureCaixaAberto()) {
      return;
    }

    if (_isProductsTab) {
      if (products.isEmpty) {
        return;
      }
      final added = await _addProduct(products.first);
      if (!added || !mounted) {
        return;
      }
      ref.read(productListProvider.notifier).onSearchChanged('');
    } else {
      if (services.isEmpty) {
        return;
      }
      final addedService = await _addService(services.first);
      if (!addedService || !mounted) {
        return;
      }
      ref.read(pdvServiceListProvider.notifier).onSearchChanged('');
    }
    _search.clear();
    _searchFocusNode.requestFocus();
  }

  Future<bool> _addProduct(Product p) async {
    if (!_ensureCaixaAberto()) {
      return false;
    }

    if (ref.read(pdvCartProvider).isMutating) {
      return false;
    }

    try {
      final added = await ref.read(pdvCartProvider.notifier).addProduct(p);
      if (!mounted) {
        return false;
      }
      if (added) {
        PharmaSnackbar.showSuccess(
          context,
          '${p.nome} adicionado ao carrinho.',
        );
      }
      return added;
    } on ApiFailure catch (e) {
      if (mounted) {
        PharmaSnackbar.showError(context, e.message);
      }
      return false;
    } catch (_) {
      if (mounted) {
        PharmaSnackbar.showError(
          context,
          'Falha ao adicionar produto. Tente novamente.',
        );
      }
      return false;
    }
  }

  Future<bool> _addService(PdvService service) async {
    if (!_ensureCaixaAberto()) {
      return false;
    }

    if (ref.read(pdvCartProvider).isMutating) {
      return false;
    }

    try {
      final added = await ref.read(pdvCartProvider.notifier).addService(service);
      if (!mounted) {
        return false;
      }
      if (added) {
        PharmaSnackbar.showSuccess(
          context,
          '${service.nome} adicionado ao carrinho.',
        );
      }
      return added;
    } on ApiFailure catch (e) {
      if (mounted) {
        PharmaSnackbar.showError(context, e.message);
      }
      return false;
    } catch (_) {
      if (mounted) {
        PharmaSnackbar.showError(
          context,
          'Falha ao adicionar serviço. Tente novamente.',
        );
      }
      return false;
    }
  }

  void _requestAddProduct(Product product) {
    unawaited(_addProduct(product));
  }

  void _requestAddService(PdvService service) {
    unawaited(_addService(service));
  }

  Future<void> _mutateCart(Future<bool> Function() action) async {
    try {
      await action();
    } on ApiFailure catch (e) {
      if (mounted) {
        PharmaSnackbar.showError(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        PharmaSnackbar.showError(
          context,
          'Falha ao atualizar o carrinho. Tente novamente.',
        );
      }
    }
  }

  Future<void> _addLine(PdvCartLine line) async {
    if (!_ensureCaixaAberto()) {
      return;
    }
    if (line.canMutateViaApi) {
      await _mutateCart(() => ref.read(pdvCartProvider.notifier).incrementLine(line));
      return;
    }
    if (line.service != null) {
      await _addService(line.service!);
      return;
    }
    if (line.product != null) {
      await _addProduct(line.product!);
    }
  }

  Future<void> _removeLine(PdvCartLine line) async {
    if (!_ensureCaixaAberto()) {
      return;
    }
    await _mutateCart(() => ref.read(pdvCartProvider.notifier).decrementLine(line));
  }

  Future<void> _deleteLine(PdvCartLine line) async {
    if (!_ensureCaixaAberto()) {
      return;
    }
    await _mutateCart(() => ref.read(pdvCartProvider.notifier).removeLine(line));
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f2) {
        _searchFocusNode.requestFocus();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _search.clear();
        _onSearchChanged('');
      }
    }
  }

  void _showMobileCart() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => _MobileCartScreen(
            onCharge: _handleCheckout,
            onAdd: _addLine,
            onRemove: _removeLine,
            onDelete: _deleteLine,
          ),
        ),
      ),
    );
  }

  Future<void> _handleCheckout() async {
    if (!_ensureCaixaAberto()) {
      return;
    }

    final cartState = ref.read(pdvCartProvider);
    if (cartState.lines.isEmpty) {
      return;
    }

    final result = await showFinalizarVendaDialog(
      context,
      total: cartState.total,
      requiresPatientDetails: cartState.requiresPatientDetails,
    );

    if (!mounted || result == null) {
      return;
    }

    PharmaSnackbar.showSuccess(
      context,
      'Pagamento confirmado. Fatura ${result.numero} — total ${_formatMoney(result.total)} (valores do servidor).',
    );

    await _showCheckoutActions(result);
  }

  Future<void> _showCheckoutActions(PdvCheckoutResult result) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Fatura emitida'),
          content: Text(
            'A fatura ${result.numero} foi emitida com sucesso. Deseja abrir o PDF ou preparar o recibo de reimpressão?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ref
                      .read(invoiceActionProvider.notifier)
                      .printReceipt(invoiceId: result.id);
                  if (!mounted) {
                    return;
                  }
                  PharmaSnackbar.showSuccess(
                    context,
                    'Recibo de reimpressão disponibilizado com sucesso.',
                  );
                } on ApiFailure catch (e) {
                  if (!mounted) {
                    return;
                  }
                  PharmaSnackbar.showError(context, e.message);
                } catch (_) {
                  if (!mounted) {
                    return;
                  }
                  PharmaSnackbar.showError(
                    context,
                    'Não foi possível preparar o recibo para impressão.',
                  );
                }
              },
              icon: const Icon(Icons.print_outlined),
              label: const Text('Reimprimir'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ref
                      .read(invoiceActionProvider.notifier)
                      .exportPdf(invoiceId: result.id);
                  if (!mounted) {
                    return;
                  }
                  PharmaSnackbar.showSuccess(
                    context,
                    'PDF da fatura disponibilizado com sucesso.',
                  );
                } on ApiFailure catch (e) {
                  if (!mounted) {
                    return;
                  }
                  PharmaSnackbar.showError(context, e.message);
                } catch (_) {
                  if (!mounted) {
                    return;
                  }
                  PharmaSnackbar.showError(
                    context,
                    'Não foi possível exportar o PDF da fatura.',
                  );
                }
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Exportar PDF'),
            ),
          ],
        );
      },
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
    final caixaState = ref.watch(caixaSessaoProvider);
    final caixaAberto = caixaState.hasSessaoAberta;
    final cartState = ref.watch(pdvCartProvider);
    final cart = cartState.lines;
    final cartItemCount =
        cart.fold<int>(0, (sum, line) => sum + line.qty);
    final mobileCartButtonHeight = t.minTouchTarget;
    final mobileFooterHeightEstimate = t.minTouchTarget + s.lg;
    final mobileCartFooterGap = s.sm;
    final activeIsLoading = _isProductsTab
        ? productState.isLoading
        : serviceState.isLoading;
    final activeIsInitialized = _isProductsTab
        ? productState.isInitialized
        : serviceState.isInitialized;
    final activeHasItems = _isProductsTab
        ? productState.items.isNotEmpty
        : serviceState.items.isNotEmpty;
    final activeErrorMessage = _isProductsTab
        ? productState.errorMessage
        : serviceState.errorMessage;

    if (activeIsLoading && !activeIsInitialized && !activeHasItems) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: s.lg),
            Text(
              _isProductsTab
                  ? 'Carregando produtos...'
                  : 'Carregando serviços...',
              style: TextStyle(color: t.textMuted),
            ),
          ],
        ),
      );
    }

    if (activeErrorMessage != null && !activeHasItems) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: t.minTouchTarget, color: t.posDanger),
            SizedBox(height: s.lg),
            Text(activeErrorMessage, style: TextStyle(color: t.textMuted)),
            SizedBox(height: s.sm),
            FilledButton(
              onPressed: _isProductsTab
                  ? productController.refreshCurrentPage
                  : serviceController.refreshCurrentQuery,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final catalogFooter = _isProductsTab
        ? _ProductsPaginationBar(
            page: productState.page,
            pageSize: productState.pageSize,
            itemCount: productState.items.length,
            hasMore: productState.hasMore,
            onPrevious: productState.page > 1
                ? () => productController.goToPage(productState.page - 1)
                : null,
            onNext: productState.hasMore
                ? () => productController.goToPage(productState.page + 1)
                : null,
          )
        : _ServiceResultsBar(
            itemCount: serviceState.items.length,
            query: serviceState.query,
          );

    final catalog = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!caixaAberto)
          Padding(
            padding: EdgeInsets.only(bottom: s.md),
            child: CaixaFechadoBanner(
              onAbrirCaixa: () => unawaited(_openAbrirCaixaDialog()),
            ),
          ),
        if (activeIsLoading)
          Padding(
            padding: EdgeInsets.only(bottom: s.sm),
            child: LinearProgressIndicator(minHeight: s.xxs),
          ),
        if (activeErrorMessage != null && activeHasItems)
          Padding(
            padding: EdgeInsets.only(bottom: s.sm),
            child: Material(
              color: t.posDanger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(t.radiusMd),
              child: Padding(
                padding: EdgeInsets.all(s.sm),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: t.posDanger, size: t.iconSm),
                    SizedBox(width: s.sm),
                    Expanded(
                      child: Text(
                        activeErrorMessage,
                        style: TextStyle(color: t.textPrimary),
                      ),
                    ),
                    TextButton(
                      onPressed: _isProductsTab
                          ? productController.refreshCurrentPage
                          : serviceController.refreshCurrentQuery,
                      child: const Text('Repetir'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Material(
          color: t.card,
          borderRadius: BorderRadius.circular(t.radiusMd),
          child: TabBar(
            controller: _catalogTabController,
            onTap: _onCatalogTabSelected,
            labelColor: t.textPrimary,
            unselectedLabelColor: t.textMuted,
            indicatorColor: t.brandBlue,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Lista de Produtos'),
              Tab(text: 'Serviços'),
            ],
          ),
        ),
        if (_isProductsTab)
          Padding(
            padding: EdgeInsets.only(bottom: s.xs),
            child: Text(
              'Preços e stock são indicativos; o total oficial é calculado no servidor ao finalizar.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: t.textMuted,
                  ),
            ),
          ),
        SizedBox(height: isMobile ? s.sm : s.md),
        TextField(
          controller: _search,
          focusNode: _searchFocusNode,
          onChanged: _onSearchChanged,
          onSubmitted: (_) => _onSearchSubmitted(
            products: productState.items,
            services: serviceState.items,
          ),
          autofocus: true,
          decoration: InputDecoration(
            isDense: isMobile,
            hintText: _isProductsTab
                ? (isMobile
                    ? 'Pesquisar produto...'
                    : 'Pesquisar por código, nome ou EAN - F2')
                : (isMobile
                    ? 'Pesquisar serviço...'
                    : 'Pesquisar por nome do serviço - F2'),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: t.brandBlue,
              size: isMobile ? t.iconSm : t.iconMd,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isProductsTab)
                  IconButton(
                    tooltip: 'Actualizar catálogo',
                    onPressed: productState.isLoading
                        ? null
                        : () => unawaited(
                              productController.refreshCatalogAndPage(),
                            ),
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: t.brandBlue,
                      size: isMobile ? t.iconSm : t.iconMd,
                    ),
                  ),
                IconButton(
                  tooltip: 'Scanner',
                  onPressed: () {},
                  icon: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: t.brandGreen,
                    size: isMobile ? t.iconSm : t.iconMd,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isMobile ? s.sm : s.md),
        Expanded(
          child: _isProductsTab
              ? _ProductCatalogList(
                  items: productState.items,
                  query: productState.query,
                  tokens: t,
                  isDesktop: isDesktop,
                  isMobile: isMobile,
                  canAdd: caixaAberto && !cartState.isMutating && !cartState.isLoading,
                  addingProductId: cartState.busyLineId,
                  onAdd: _requestAddProduct,
                  mobileCartButtonHeight: mobileCartButtonHeight,
                )
              : _ServiceCatalogList(
                  items: serviceState.items,
                  query: serviceState.query,
                  tokens: t,
                  isDesktop: isDesktop,
                  isMobile: isMobile,
                  canAdd: caixaAberto && !cartState.isMutating && !cartState.isLoading,
                  onAdd: _requestAddService,
                  mobileCartButtonHeight: mobileCartButtonHeight,
                ),
        ),
        if (!isMobile) ...[
          SizedBox(height: s.sm),
          catalogFooter,
        ],
      ],
    );
    final mobileCatalog = isMobile ? catalog : catalog;

    final cartPane = _CartPane(
      subtotal: cartState.subtotal,
      tax: cartState.tax,
      taxLabel: cartState.taxLabel,
      discount: cartState.discount,
      total: cartState.total,
      cart: cart,
      t: t,
      compact: isMobile || isTablet,
      caixaAberto: caixaAberto,
      isCartBusy: cartState.isMutating || cartState.isLoading,
      onCharge: (!caixaAberto || cart.isEmpty) ? null : _handleCheckout,
      onAdd: (line) => unawaited(_addLine(line)),
      onRemove: (line) => unawaited(_removeLine(line)),
      onDelete: (line) => unawaited(_deleteLine(line)),
      isLineBusy: cartState.isLineBusy,
    );

        Widget content;
        if (isDesktop) {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: catalog),
              SizedBox(width: s.lg),
              SizedBox(
                width: 480,
                child: cartPane,
              ),
            ],
          );
        } else {
          content = Stack(
            children: [
              Column(
                children: [
                  Expanded(child: mobileCatalog),
                  SizedBox(height: s.sm),
                  catalogFooter,
                ],
              ),
              Positioned(
                right: s.xs,
                bottom: mobileFooterHeightEstimate + mobileCartFooterGap,
                child: SafeArea(
                  minimum: EdgeInsets.only(bottom: s.xs),
                  child: SizedBox(
                    height: mobileCartButtonHeight,
                    child: FloatingActionButton.extended(
                      onPressed: _showMobileCart,
                      icon: Icon(
                        Icons.shopping_cart_rounded,
                        size: t.iconSm,
                      ),
                      label: Text(
                        '$cartItemCount Itens • ${_formatMoney(cartState.total)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      extendedPadding: EdgeInsets.symmetric(horizontal: s.md),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: t.brandGreen,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: _handleKeyEvent,
          child: content,
        );
  }
}

class _ProductCatalogList extends StatelessWidget {
  const _ProductCatalogList({
    required this.items,
    required this.query,
    required this.tokens,
    required this.isDesktop,
    required this.isMobile,
    required this.canAdd,
    required this.addingProductId,
    required this.onAdd,
    required this.mobileCartButtonHeight,
  });

  final List<Product> items;
  final String query;
  final PharmaTokens tokens;
  final bool isDesktop;
  final bool isMobile;
  final bool canAdd;
  final String? addingProductId;
  final void Function(Product product) onAdd;
  final double mobileCartButtonHeight;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    if (items.isEmpty) {
      return _CatalogEmptyState(
        icon: Icons.inventory_2_outlined,
        title: query.isEmpty
            ? 'Nenhum produto disponível.'
            : 'Nenhum produto encontrado.',
        subtitle: query.isEmpty ? null : 'Tente outro nome, código ou EAN.',
        tokens: tokens,
      );
    }

    return ListView.separated(
      padding: isMobile
          ? EdgeInsets.only(bottom: mobileCartButtonHeight + s.xl)
          : null,
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemBuilder: (context, i) {
        final product = items[i];
        final stockIndisponivel = product.estoqueAtual <= 0;
        final stockColor =
            stockIndisponivel ? tokens.posDanger : tokens.textMuted;
        final lineId = 'produto:${product.id}';
        final isAddingThis = addingProductId == lineId;
        final canInteract = canAdd && !isAddingThis;

        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: stockIndisponivel
                  ? tokens.posDanger.withValues(alpha: 0.05)
                  : tokens.card,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              border: Border.all(
                color: stockIndisponivel
                    ? tokens.posDanger.withValues(alpha: 0.35)
                    : tokens.border.withValues(alpha: 0.45),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              onTap: canInteract ? () => onAdd(product) : null,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? s.md : s.lg,
                  isMobile ? s.sm : s.md,
                  isMobile ? s.sm : s.lg,
                  isMobile ? s.sm : s.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: isDesktop ? 8 : 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.nome,
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: tokens.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((product.substanciaActiva ?? '').isNotEmpty) ...[
                            SizedBox(height: s.xxs),
                            Text(
                              product.substanciaActiva!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: tokens.textSecondary),
                            ),
                          ],
                          SizedBox(height: s.xs),
                          Text(
                            'PV ${_formatMoney(product.precoVenda)} • Date Exp. ${_formatDate(product.dataValidade)} • Lote ${product.lote ?? '-'} • Stock ${product.estoqueAtual.toInt()}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: stockColor),
                          ),
                          if (product.requiresPsychotropicBook || stockIndisponivel)
                            Padding(
                              padding: EdgeInsets.only(top: s.xs),
                              child: Wrap(
                                spacing: s.xs,
                                runSpacing: s.xs,
                                children: [
                                  if (product.requiresPsychotropicBook)
                                    Chip(
                                      visualDensity: VisualDensity.compact,
                                      label: const Text('Psicotrópico'),
                                      backgroundColor: tokens.psychotropic
                                          .withValues(alpha: 0.2),
                                    ),
                                  if (stockIndisponivel)
                                    Chip(
                                      avatar: Icon(
                                        Icons.warning_amber_rounded,
                                        size: tokens.iconSm,
                                        color: tokens.posDanger,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      label: const Text('Stock indisponível'),
                                      labelStyle: TextStyle(
                                        color: tokens.posDanger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      backgroundColor: tokens.posDanger
                                          .withValues(alpha: 0.12),
                                      side: BorderSide(
                                        color: tokens.posDanger
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: s.sm),
                    SizedBox(
                      width: isMobile ? tokens.minTouchTarget : null,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: canInteract ? () => onAdd(product) : null,
                          child: isAddingThis
                              ? SizedBox(
                                  width: tokens.iconSm,
                                  height: tokens.iconSm,
                                  child: CircularProgressIndicator(
                                    strokeWidth: s.xxs,
                                    color: tokens.bgPrimary,
                                  ),
                                )
                              : Text(isMobile ? '+' : 'Add'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ServiceCatalogList extends StatelessWidget {
  const _ServiceCatalogList({
    required this.items,
    required this.query,
    required this.tokens,
    required this.isDesktop,
    required this.isMobile,
    required this.canAdd,
    required this.onAdd,
    required this.mobileCartButtonHeight,
  });

  final List<PdvService> items;
  final String query;
  final PharmaTokens tokens;
  final bool isDesktop;
  final bool isMobile;
  final bool canAdd;
  final void Function(PdvService service) onAdd;
  final double mobileCartButtonHeight;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    if (items.isEmpty) {
      return _CatalogEmptyState(
        icon: Icons.medical_services_outlined,
        title: query.isEmpty
            ? 'Nenhum serviço disponível.'
            : 'Nenhum serviço encontrado.',
        subtitle: query.isEmpty ? null : 'Tente outro nome de serviço.',
        tokens: tokens,
      );
    }

    return ListView.separated(
      padding: isMobile
          ? EdgeInsets.only(bottom: mobileCartButtonHeight + s.xl)
          : null,
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemBuilder: (context, i) {
        final service = items[i];
        return Material(
          color: tokens.card,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            onTap: canAdd ? () => onAdd(service) : null,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? s.md : s.lg,
                isMobile ? s.sm : s.md,
                isMobile ? s.sm : s.lg,
                isMobile ? s.sm : s.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: isDesktop ? 8 : 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.nome,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: tokens.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((service.tipoServicoClinico ?? '').isNotEmpty) ...[
                          SizedBox(height: s.xxs),
                          Text(
                            service.tipoServicoClinico!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: tokens.textSecondary),
                          ),
                        ],
                        SizedBox(height: s.xs),
                        Text(
                          'PV ${_formatMoney(service.preco)} • Serviço clínico ${service.tipoServicoClinico ?? '-'}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: tokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: s.sm),
                  SizedBox(
                    width: isMobile ? tokens.minTouchTarget : null,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: canAdd ? () => onAdd(service) : null,
                        child: Text(isMobile ? '+' : 'Add'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CatalogEmptyState extends StatelessWidget {
  const _CatalogEmptyState({
    required this.icon,
    required this.title,
    required this.tokens,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final PharmaTokens tokens;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: tokens.minTouchTarget, color: tokens.border),
          SizedBox(height: s.md),
          Text(
            title,
            style: TextStyle(
              color: tokens.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.textMuted),
            ),
        ],
      ),
    );
  }
}

class _ServiceResultsBar extends StatelessWidget {
  const _ServiceResultsBar({
    required this.itemCount,
    required this.query,
  });

  final int itemCount;
  final String query;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: s.md,
        vertical: s.sm,
      ),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.5)),
      ),
      child: Text(
        itemCount == 0
            ? (query.isEmpty ? 'Sem serviços disponíveis' : 'Sem serviços para esta pesquisa')
            : 'Mostrando $itemCount serviço(s)',
        style: TextStyle(color: t.textMuted),
      ),
    );
  }
}

class _MobileCartScreen extends ConsumerWidget {
  const _MobileCartScreen({
    required this.onCharge,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  });

  final Future<void> Function() onCharge;
  final Future<void> Function(PdvCartLine line) onAdd;
  final Future<void> Function(PdvCartLine line) onRemove;
  final Future<void> Function(PdvCartLine line) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final caixaAberto = ref.watch(caixaSessaoProvider).hasSessaoAberta;
    final cartState = ref.watch(pdvCartProvider);
    final cart = cartState.lines;

    return Scaffold(
      backgroundColor: t.bgPrimary,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Carrinho Atual'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(s.md),
          child: _CartPane(
            subtotal: cartState.subtotal,
            tax: cartState.tax,
            taxLabel: cartState.taxLabel,
            discount: cartState.discount,
            total: cartState.total,
            cart: cart,
            t: t,
            compact: true,
            caixaAberto: caixaAberto,
            isCartBusy: cartState.isMutating || cartState.isLoading,
            onCharge: (!caixaAberto || cart.isEmpty)
                ? null
                : () {
                    unawaited(onCharge());
                  },
            onAdd: (line) => unawaited(onAdd(line)),
            onRemove: (line) => unawaited(onRemove(line)),
            onDelete: (line) => unawaited(onDelete(line)),
            isLineBusy: cartState.isLineBusy,
          ),
        ),
      ),
    );
  }
}

class _CartPane extends StatelessWidget {
  const _CartPane({
    required this.subtotal,
    required this.tax,
    required this.taxLabel,
    required this.discount,
    required this.total,
    required this.cart,
    required this.t,
    required this.compact,
    required this.caixaAberto,
    required this.isCartBusy,
    required this.onCharge,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
    required this.isLineBusy,
  });

  final double subtotal;
  final double tax;
  final String taxLabel;
  final double discount;
  final double total;
  final List<PdvCartLine> cart;
  final PharmaTokens t;
  final bool compact;
  final bool caixaAberto;
  final bool isCartBusy;
  final VoidCallback? onCharge;
  final void Function(PdvCartLine) onAdd;
  final void Function(PdvCartLine) onRemove;
  final void Function(PdvCartLine) onDelete;
  final bool Function(String lineId) isLineBusy;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final pad = compact ? EdgeInsets.all(s.md) : t.density.cardPadding;
    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: Padding(
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compact)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CARRINHO ATUAL',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: t.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Icon(
                    Icons.shopping_basket_rounded,
                    color: t.brandBlue,
                    size: t.iconMd,
                  ),
                ],
              ),
            Divider(height: compact ? s.md : s.xxl, color: t.border.withValues(alpha: 0.35)),
            Expanded(
              child: cart.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.remove_shopping_cart_rounded,
                            size: t.minTouchTarget,
                            color: t.border,
                          ),
                          SizedBox(height: s.md),
                          Text(
                            'Carrinho vazio',
                            style: TextStyle(color: t.textMuted, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Escaneie ou pesquise um produto ou serviço',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: t.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: cart.length,
                      separatorBuilder: (_, _) => Divider(color: t.border.withValues(alpha: 0.3)),
                      itemBuilder: (context, i) {
                        final line = cart[i];
                        final lineBusy = isLineBusy(line.id);
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: s.xs),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.nome,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: t.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    SizedBox(height: s.xxs),
                                    Text(
                                      '${_formatMoney(line.precoUnitario)} / un',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(color: t.textMuted),
                                    ),
                                    if ((line.service?.tipoServicoClinico ?? '').isNotEmpty)
                                      Text(
                                        line.service!.tipoServicoClinico!,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(color: t.textSecondary),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatMoney(line.lineTotal),
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: t.brandGreen,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  SizedBox(height: s.xs),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox.square(
                                        dimension: t.minTouchTarget,
                                        child: IconButton(
                                          icon: const Icon(Icons.remove_circle_outline_rounded),
                                          color: t.textMuted,
                                          iconSize: t.iconMd,
                                          onPressed: () => onRemove(line),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: s.sm),
                                        child: Text(
                                          '${line.qty}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: t.textPrimary,
                                          ),
                                        ),
                                      ),
                                      SizedBox.square(
                                        dimension: t.minTouchTarget,
                                        child: IconButton(
                                          icon: lineBusy
                                              ? SizedBox(
                                                  width: t.iconSm,
                                                  height: t.iconSm,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: s.xxs,
                                                    color: t.brandBlue,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.add_circle_outline_rounded,
                                                ),
                                          color: t.brandBlue,
                                          iconSize: t.iconMd,
                                          onPressed:
                                              (caixaAberto && !isCartBusy && !lineBusy)
                                                  ? () => onAdd(line)
                                                  : null,
                                        ),
                                      ),
                                      SizedBox(width: s.sm),
                                      SizedBox.square(
                                        dimension: t.minTouchTarget,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded),
                                          color: t.posDanger,
                                          iconSize: t.iconMd,
                                          onPressed: () => onDelete(line),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            
            // Totals Section
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: TextStyle(color: t.textSecondary)),
                    Text(_formatMoney(subtotal), style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: s.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Desconto', style: TextStyle(color: t.textSecondary)),
                    Text('- ${_formatMoney(discount)}', style: TextStyle(color: t.posDanger, fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: s.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(taxLabel, style: TextStyle(color: t.textSecondary)),
                    Text(_formatMoney(tax), style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: s.sm),
            Container(
              padding: EdgeInsets.all(s.sm),
              decoration: BoxDecoration(
                color: t.brandGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(t.radiusMd),
                border: Border.all(color: t.brandGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: t.brandGreen, fontWeight: FontWeight.w900)),
                  Text(
                    _formatMoney(total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: t.brandGreen,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? s.sm : s.md),
            
            FilledButton.icon(
              onPressed: onCharge,
              icon: Icon(
                Icons.point_of_sale_rounded,
                size: compact ? t.iconSm : t.iconMd,
              ),
              label: Text(
                compact ? 'Finalizar' : 'Finalizar Venda',
                maxLines: 1,
              ),
            ),
            if (!compact) ...[
              SizedBox(height: s.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: t.iconSm, color: t.textMuted),
                  SizedBox(width: s.xs),
                  Text(
                    'FEFO automático aplicado na dispensa',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: t.textMuted),
                  ),
                ],
              ),
            ],
          ],
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
                      style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600),
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
