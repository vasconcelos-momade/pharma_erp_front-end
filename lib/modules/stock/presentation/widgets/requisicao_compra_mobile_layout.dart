import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../domain/entities/requisicao.dart';
import '../providers/requisicao_provider.dart';
import 'requisicao_compra_right_pane.dart';
import 'requisicao_hub_formatters.dart';
import 'requisicao_products_tab.dart';

class RequisicaoMobilePurchaseSummaryBar extends StatelessWidget {
  const RequisicaoMobilePurchaseSummaryBar({
    super.key,
    required this.requisicao,
    required this.onOpen,
  });

  final RequisicaoDetalhe requisicao;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final total = requisicao.total ?? 0;

    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(t.radiusXl),
      elevation: 2,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(t.radiusXl),
        child: Padding(
          padding: EdgeInsets.all(s.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${requisicao.totalItens} item${requisicao.totalItens == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: s.xxs),
                    Text(
                      'Total: ${requisicaoFormatMoney(total)}',
                      style: TextStyle(color: t.textMuted),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onOpen,
                child: const Text('Ver detalhes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RequisicaoMobilePurchasePaneScreen extends ConsumerWidget {
  const RequisicaoMobilePurchasePaneScreen({
    super.key,
    required this.onConfirm,
    required this.onEditHeader,
    required this.onEditItem,
    required this.onRemoveItem,
  });

  final Future<void> Function() onConfirm;
  final Future<void> Function() onEditHeader;
  final Future<void> Function(RequisicaoItem item) onEditItem;
  final Future<void> Function(RequisicaoItem item) onRemoveItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final compraState = ref.watch(requisicaoCompraProvider);

    return Scaffold(
      backgroundColor: t.bgPrimary,
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Requisição Atual'),
      ),
      body: SafeArea(
        child: RequisicaoCompraRightPane(
          state: compraState,
          fullscreen: true,
          onConfirm: onConfirm,
          onEditHeader: onEditHeader,
          onEditItem: onEditItem,
          onRemoveItem: onRemoveItem,
        ),
      ),
    );
  }
}

class RequisicaoCompraMobileLayout extends StatelessWidget {
  const RequisicaoCompraMobileLayout({
    super.key,
    required this.leftPane,
    required this.compraState,
    required this.productState,
    required this.productController,
    required this.onOpenPurchasePane,
  });

  final Widget leftPane;
  final RequisicaoState compraState;
  final ProductListState productState;
  final RequisicaoProductListController productController;
  final VoidCallback onOpenPurchasePane;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final activePurchase = compraState.activeRequisicao;
    final showPagination =
        compraState.activeTab == RequisicaoTab.produtos &&
        productState.isInitialized;
    final showSummary = activePurchase != null;
    final paginationHeight = showPagination ? (t.minTouchTarget + s.xl) : 0.0;
    final summaryHeight = showSummary ? 84.0 : 0.0;
    final footerGap = showPagination && showSummary ? s.sm : 0.0;
    final bottomOverlayHeight = paginationHeight + summaryHeight + footerGap;
    final contentBottomPadding = bottomOverlayHeight + s.md;

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(bottom: contentBottomPadding),
            child: leftPane,
          ),
        ),
        if (showSummary || showPagination)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSummary)
                    Padding(
                      padding: EdgeInsets.fromLTRB(s.xs, 0, s.xs, 0),
                      child: RequisicaoMobilePurchaseSummaryBar(
                        requisicao: activePurchase,
                        onOpen: onOpenPurchasePane,
                      ),
                    ),
                  if (showSummary && showPagination) SizedBox(height: s.sm),
                  if (showPagination)
                    Padding(
                      padding: EdgeInsets.fromLTRB(s.xs, 0, s.xs, s.xs),
                      child: RequisicaoProductsPaginationBar(
                        page: productState.page,
                        pageSize: productState.pageSize,
                        itemCount: productState.items.length,
                        hasMore: productState.hasMore,
                        onPrevious:
                            productState.page > 1 && !productState.isLoading
                            ? () => productController.goToPage(
                                productState.page - 1,
                              )
                            : null,
                        onNext:
                            productState.hasMore && !productState.isLoading
                            ? () => productController.goToPage(
                                productState.page + 1,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class RequisicaoCompraDesktopLayout extends StatelessWidget {
  const RequisicaoCompraDesktopLayout({
    super.key,
    required this.leftPane,
    required this.rightPane,
    required this.isTablet,
    required this.isWideScreen,
    required this.gap,
  });

  final Widget leftPane;
  final Widget rightPane;
  final bool isTablet;
  final bool isWideScreen;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 11, child: leftPane),
          SizedBox(width: gap),
          Expanded(flex: 9, child: rightPane),
        ],
      );
    }

    final rightPaneWidth = isWideScreen ? 560.0 : 520.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: leftPane),
        SizedBox(width: gap),
        SizedBox(width: rightPaneWidth, child: rightPane),
      ],
    );
  }
}
