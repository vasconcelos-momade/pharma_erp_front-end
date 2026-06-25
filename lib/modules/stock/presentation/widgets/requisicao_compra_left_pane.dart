import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../pharmacy/products/domain/entities/categoria_produto.dart';
import '../../../pharmacy/products/domain/entities/product.dart';
import '../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../domain/entities/requisicao.dart';
import '../providers/requisicao_provider.dart';
import 'requisicao_products_tab.dart';
import 'requisicao_resumo_card.dart';

class RequisicaoCompraLeftPane extends StatefulWidget {
  const RequisicaoCompraLeftPane({
    super.key,
    required this.activeTab,
    required this.productState,
    required this.pendingRequisicoes,
    required this.historyRequisicoes,
    required this.isLoadingLists,
    required this.activeRequisicaoId,
    required this.searchController,
    required this.canAddItems,
    required this.onSearchChanged,
    required this.onCategoriaChanged,
    required this.onRefreshProducts,
    required this.onGoToPage,
    required this.onTabChanged,
    required this.onSelectProduct,
    required this.onSelectPendingPurchase,
    required this.onSelectFinalizedPurchase,
    this.showInlinePagination = true,
  });

  final RequisicaoTab activeTab;
  final ProductListState productState;
  final List<RequisicaoResumo> pendingRequisicoes;
  final List<RequisicaoResumo> historyRequisicoes;
  final bool isLoadingLists;
  final String? activeRequisicaoId;
  final TextEditingController searchController;
  final bool canAddItems;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CategoriaProduto?> onCategoriaChanged;
  final Future<void> Function() onRefreshProducts;
  final Future<void> Function(int page) onGoToPage;
  final ValueChanged<RequisicaoTab> onTabChanged;
  final ValueChanged<Product> onSelectProduct;
  final ValueChanged<String> onSelectPendingPurchase;
  final ValueChanged<String> onSelectFinalizedPurchase;
  final bool showInlinePagination;

  @override
  State<RequisicaoCompraLeftPane> createState() =>
      _RequisicaoCompraLeftPaneState();
}

class _RequisicaoCompraLeftPaneState extends State<RequisicaoCompraLeftPane>
    with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(RequisicaoCompraLeftPane oldWidget) {
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

  int _indexForTab(RequisicaoTab tab) {
    return switch (tab) {
      RequisicaoTab.produtos => 0,
      RequisicaoTab.pendentes => 1,
      RequisicaoTab.historico => 2,
    };
  }

  RequisicaoTab _tabForIndex(int index) {
    return switch (index) {
      0 => RequisicaoTab.produtos,
      1 => RequisicaoTab.pendentes,
      2 => RequisicaoTab.historico,
      _ => RequisicaoTab.produtos,
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
            isScrollable: true,
            onTap: (index) => widget.onTabChanged(_tabForIndex(index)),
            labelColor: t.textPrimary,
            unselectedLabelColor: t.textMuted,
            indicatorColor: t.brandBlue,
            dividerColor: Colors.transparent,
            labelPadding: EdgeInsets.symmetric(horizontal: s.sm),
            tabs: [
              Tab(height: t.minTouchTarget, text: 'Produtos'),
              Tab(
                height: t.minTouchTarget,
                text: 'Pendentes (${widget.pendingRequisicoes.length})',
              ),
              Tab(
                height: t.minTouchTarget,
                text: 'Finalizadas (${widget.historyRequisicoes.length})',
              ),
            ],
          ),
        ),
        SizedBox(height: s.md),
        Expanded(
          child: switch (widget.activeTab) {
            RequisicaoTab.produtos => RequisicaoProductsTab(
              productState: widget.productState,
              searchController: widget.searchController,
              canAddItems: widget.canAddItems,
              onSearchChanged: widget.onSearchChanged,
              onCategoriaChanged: widget.onCategoriaChanged,
              onRefreshProducts: widget.onRefreshProducts,
              onGoToPage: widget.onGoToPage,
              onSelectProduct: widget.onSelectProduct,
              showPagination: widget.showInlinePagination,
            ),
            RequisicaoTab.pendentes => RequisicaoResumoListTab(
              title: 'Requisições Pendentes',
              subtitle:
                  'Selecione uma requisição pendente para carregar os itens e voltar automaticamente para a tab Produtos.',
              isLoading: widget.isLoadingLists,
              requisicoes: widget.pendingRequisicoes,
              activeRequisicaoId: widget.activeRequisicaoId,
              emptyTitle: 'Nenhuma requisição pendente',
              emptySubtitle:
                  'Inicie uma nova requisição para criar o registo no backend.',
              emptyIcon: Icons.assignment_outlined,
              onSelect: widget.onSelectPendingPurchase,
            ),
            RequisicaoTab.historico => RequisicaoResumoListTab(
              title: 'Requisições Finalizadas',
              subtitle:
                  'Apenas visualização. Abra um card para consultar a requisição no painel da direita.',
              isLoading: widget.isLoadingLists,
              requisicoes: widget.historyRequisicoes,
              activeRequisicaoId: widget.activeRequisicaoId,
              emptyTitle: 'Nenhuma requisição finalizada',
              emptySubtitle:
                  'As requisições confirmadas aparecerão aqui automaticamente.',
              emptyIcon: Icons.assignment_outlined,
              onSelect: widget.onSelectFinalizedPurchase,
            ),
          },
        ),
      ],
    );
  }
}
