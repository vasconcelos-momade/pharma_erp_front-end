import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../pharmacy/products/domain/entities/product.dart';
import '../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../domain/entities/requisicao.dart';
import '../../data/repositories/requisicao_repository_impl.dart';
import '../providers/requisicao_provider.dart';
import 'editar_requisicao_dialog.dart';
import 'requisicao_products_tab.dart';
import 'requisicao_resumo_card.dart';

String stockFlowFormatQuantity(num value) {
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

String stockFlowFormatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

DateTime? stockFlowParseDateInput(String? value) {
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

  final displayMatch = RegExp(
    r'^(\d{2})/(\d{2})/(\d{4})$',
  ).firstMatch(normalized);
  if (displayMatch != null) {
    final day = int.tryParse(displayMatch.group(1)!);
    final month = int.tryParse(displayMatch.group(2)!);
    final year = int.tryParse(displayMatch.group(3)!);
    if (day != null && month != null && year != null) {
      final candidate = DateTime(year, month, day);
      if (candidate.year == year &&
          candidate.month == month &&
          candidate.day == day) {
        return candidate;
      }
    }
  }

  return null;
}

String stockFlowNormalizeDateInput(String? value) {
  final parsed = stockFlowParseDateInput(value);
  if (parsed == null) {
    return value?.trim() ?? '';
  }
  return stockFlowFormatDate(parsed);
}

bool stockFlowSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _StockFlowDateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();

    for (var i = 0; i < limitedDigits.length; i++) {
      if ((i == 2 || i == 4) && buffer.isNotEmpty) {
        buffer.write('/');
      }
      buffer.write(limitedDigits[i]);
    }

    final formatted = buffer.toString();
    var digitsBeforeCursor = 0;
    final cursor = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    digitsBeforeCursor = RegExp(
      r'\d',
    ).allMatches(newValue.text.substring(0, cursor)).length;
    digitsBeforeCursor = digitsBeforeCursor.clamp(0, limitedDigits.length);

    var selectionOffset = 0;
    var seenDigits = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        seenDigits++;
        if (seenDigits == digitsBeforeCursor) {
          selectionOffset = i + 1;
          break;
        }
      }
    }
    if (selectionOffset == 0) {
      selectionOffset = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
      composing: TextRange.empty,
    );
  }
}

String stockFlowFormatRouteLabel(String? origem, String? destino) {
  return formatRequisicaoRouteLabel(origem, destino);
}

String stockFlowItemLoteNumero(RequisicaoItem item) {
  return item.lote?.numeroLote ?? item.numeroLote ?? '-';
}

String stockFlowItemLoteValidade(RequisicaoItem item) {
  final date = item.lote?.dataValidade ?? item.dataValidade;
  if (date == null) {
    return '-';
  }
  return stockFlowFormatDate(date);
}

class RequisicaoStockFlowView extends ConsumerStatefulWidget {
  const RequisicaoStockFlowView({
    super.key,
    required this.searchController,
    required this.tipo,
  });

  final TextEditingController searchController;
  final RequisicaoTipo tipo;

  @override
  ConsumerState<RequisicaoStockFlowView> createState() =>
      _RequisicaoStockFlowViewState();
}

class _RequisicaoStockFlowViewState
    extends ConsumerState<RequisicaoStockFlowView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(requisicaoProvider.notifier).initializeScope(widget.tipo);
    });
  }

  @override
  void didUpdateWidget(RequisicaoStockFlowView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tipo != widget.tipo) {
      ref.read(requisicaoProvider.notifier).initializeScope(widget.tipo);
    }
  }

  Future<void> _handleProduct(Product product) async {
    final requisicaoState = ref.read(requisicaoProvider);
    if (!requisicaoState.canEditActiveRequisicao) {
      PharmaFeedback.error(
        context,
        'Inicie ou seleccione uma requisição pendente antes de adicionar itens.',
      );
      return;
    }

    final draft = await showDialog<RequisicaoItemDraft>(
      context: context,
      builder: (_) => _RequisicaoLoteDialog(
        product: product,
        tipo: requisicaoState.activeRequisicao!.tipo,
      ),
    );

    if (!mounted || draft == null) {
      return;
    }

    await ref
        .read(requisicaoProvider.notifier)
        .addItemToActiveRequisition(draft: draft);
  }

  Future<void> _handleEditItem(RequisicaoItem item) async {
    final requisicaoState = ref.read(requisicaoProvider);
    if (!requisicaoState.canEditActiveRequisicao) {
      PharmaFeedback.error(
        context,
        'Seleccione uma requisição pendente antes de editar itens.',
      );
      return;
    }

    final quantidade = await showDialog<double>(
      context: context,
      builder: (_) => _EditStockFlowItemDialog(item: item),
    );

    if (!mounted || quantidade == null) {
      return;
    }

    await ref
        .read(requisicaoProvider.notifier)
        .updateItemInActiveRequisition(
          item: item,
          quantidadeSolicitada: quantidade,
        );
  }

  Future<void> _handleEditHeader() async {
    final requisicao = ref.read(requisicaoProvider).activeRequisicao;
    if (requisicao == null || !requisicao.status.isEditable) {
      PharmaFeedback.error(
        context,
        'Seleccione uma requisição pendente antes de editar o cabeçalho.',
      );
      return;
    }

    final result = await showDialog<EditarRequisicaoDialogResult>(
      context: context,
      builder: (_) => EditarRequisicaoDialog(requisicao: requisicao),
    );

    if (!mounted || result == null) {
      return;
    }

    await ref
        .read(requisicaoProvider.notifier)
        .updateActiveRequisitionHeader(request: result.toRequest());
  }

  Future<void> _confirmRemoveItem(RequisicaoItem item) async {
    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Confirmar remoção',
      message:
          'Deseja remover o item "${item.produtoNome}" da requisição?\n\n'
          'Lote: ${stockFlowItemLoteNumero(item)}\n'
          'Quantidade: ${stockFlowFormatQuantity(item.quantidade)}',
      confirmText: 'Remover',
      cancelText: 'Cancelar',
      destructive: true,
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await ref
        .read(requisicaoProvider.notifier)
        .removeItemFromActiveRequisition(item.id);
  }

  Future<void> _approveRequisition() async {
    final state = ref.read(requisicaoProvider);
    if (!state.canApproveActiveRequisicao) {
      return;
    }

    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Aprovar requisição',
      message:
          'A aprovação valida a requisição e regista os movimentos documentais. Deseja continuar?',
      confirmText: 'Aprovar',
      cancelText: 'Voltar',
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await ref.read(requisicaoProvider.notifier).approveActiveRequisition();
  }

  Future<void> _rejectRequisition() async {
    final state = ref.read(requisicaoProvider);
    if (!state.canRejectActiveRequisicao) {
      return;
    }

    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Rejeitar requisição',
      message: 'Deseja rejeitar a requisição activa?',
      confirmText: 'Rejeitar',
      cancelText: 'Voltar',
      destructive: true,
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await ref.read(requisicaoProvider.notifier).rejectActiveRequisition();
  }

  Future<void> _cancelRequisition() async {
    final state = ref.read(requisicaoProvider);
    if (!state.canCancelActiveRequisicao) {
      return;
    }

    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Cancelar requisição',
      message: 'Deseja cancelar a requisição activa?',
      confirmText: 'Cancelar requisição',
      cancelText: 'Voltar',
      destructive: true,
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await ref.read(requisicaoProvider.notifier).cancelActiveRequisition();
  }

  Future<void> _showMobileStockFlowPane() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _MobileStockFlowPaneScreen(
          onApprove: _approveRequisition,
          onReject: _rejectRequisition,
          onCancel: _cancelRequisition,
          onEditHeader: _handleEditHeader,
          onEditItem: _handleEditItem,
          onRemoveItem: _confirmRemoveItem,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width <= 920;
    final productState = ref.watch(requisicaoProductListProvider);
    final requisicaoState = ref.watch(requisicaoProvider);
    final productController = ref.read(requisicaoProductListProvider.notifier);
    final canAddProducts =
        requisicaoState.canEditActiveRequisicao &&
        !requisicaoState.isAddingItem &&
        !requisicaoState.isApprovingRequisicao &&
        !requisicaoState.isRejectingRequisicao &&
        !requisicaoState.isCancellingRequisicao;
    final requisicaoController = ref.read(requisicaoProvider.notifier);

    // Use a listener to sync search controller without modifying during build
    ref.listen<ProductListState>(requisicaoProductListProvider, (
      previous,
      next,
    ) {
      if (widget.searchController.text != next.query) {
        widget.searchController.value = TextEditingValue(
          text: next.query,
          selection: TextSelection.collapsed(offset: next.query.length),
        );
      }
    });

    ref.listen<RequisicaoState>(requisicaoProvider, (previous, next) {
      if (!mounted) {
        return;
      }
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        PharmaFeedback.error(context, next.errorMessage!);
      }
      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        PharmaFeedback.success(context, next.successMessage!);
      }
    });

    final leftPane = _LeftPane(
      activeTab: requisicaoState.activeTab,
      productState: productState,
      requisicaoState: requisicaoState,
      canAddProducts: canAddProducts,
      searchController: widget.searchController,
      onSearchChanged: productController.onSearchChanged,
      onRefreshProducts: productController.refreshCurrentPage,
      onGoToPage: productController.goToPage,
      onTabChanged: requisicaoController.setActiveTab,
      onSelectProduct: _handleProduct,
      onSelectPendingRequisition: requisicaoController.selectPendingRequisition,
      onSelectHistoryRequisition: requisicaoController.selectHistoryRequisition,
      showInlinePagination: !isMobile,
    );

    final rightPane = _RightPane(
      state: requisicaoState,
      onApprove: _approveRequisition,
      onReject: _rejectRequisition,
      onCancel: _cancelRequisition,
      onEditHeader: _handleEditHeader,
      onEditItem: _handleEditItem,
      onRemoveItem: _confirmRemoveItem,
    );

    if (isMobile) {
      final activeRequisicao = requisicaoState.activeRequisicao;
      final showPagination =
          requisicaoState.activeTab == RequisicaoTab.produtos &&
          productState.isInitialized;
      final showSummary = activeRequisicao != null;
      final paginationHeight = showPagination ? (t.minTouchTarget + s.lg) : 0.0;
      final summaryHeight = showSummary ? 88.0 : 0.0;
      final footerGap = showPagination && showSummary ? s.sm : 0.0;
      final bottomOverlayHeight = paginationHeight + summaryHeight + footerGap;
      final contentBottomPadding =
          bottomOverlayHeight + (showSummary ? t.minTouchTarget : 0) + s.xl;

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
                        child: _MobileStockFlowSummaryBar(
                          requisicao: activeRequisicao!,
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
          if (showSummary)
            Positioned(
              right: s.xs,
              bottom: bottomOverlayHeight + s.md,
              child: SafeArea(
                top: false,
                minimum: EdgeInsets.only(bottom: s.xs),
                child: FloatingActionButton.extended(
                  heroTag: 'open-stock-flow-fab-${widget.tipo.name}',
                  onPressed: _showMobileStockFlowPane,
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Ver requisição'),
                ),
              ),
            ),
        ],
      );
    }

    return SizedBox(
      height: 760,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: leftPane),
          SizedBox(width: s.lg),
          Expanded(flex: 5, child: rightPane),
        ],
      ),
    );
  }
}

class _MobileStockFlowSummaryBar extends StatelessWidget {
  const _MobileStockFlowSummaryBar({required this.requisicao});

  final RequisicaoDetalhe requisicao;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(t.radiusXl),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(s.md),
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
              'Quantidade: ${stockFlowFormatQuantity(requisicao.quantidadeTotal)}',
              style: TextStyle(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileStockFlowPaneScreen extends ConsumerWidget {
  const _MobileStockFlowPaneScreen({
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
    required this.onEditHeader,
    required this.onEditItem,
    required this.onRemoveItem,
  });

  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;
  final Future<void> Function() onCancel;
  final Future<void> Function() onEditHeader;
  final ValueChanged<RequisicaoItem> onEditItem;
  final ValueChanged<RequisicaoItem> onRemoveItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final requisicaoState = ref.watch(requisicaoProvider);

    return Scaffold(
      backgroundColor: t.bgPrimary,
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Requisição Atual'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(s.md),
          child: _RightPane(
            state: requisicaoState,
            onApprove: onApprove,
            onReject: onReject,
            onCancel: onCancel,
            onEditHeader: onEditHeader,
            onEditItem: onEditItem,
            onRemoveItem: onRemoveItem,
          ),
        ),
      ),
    );
  }
}

class _LeftPane extends StatefulWidget {
  const _LeftPane({
    required this.activeTab,
    required this.productState,
    required this.requisicaoState,
    required this.canAddProducts,
    required this.searchController,
    required this.onSearchChanged,
    required this.onRefreshProducts,
    required this.onGoToPage,
    required this.onTabChanged,
    required this.onSelectProduct,
    required this.onSelectPendingRequisition,
    required this.onSelectHistoryRequisition,
    this.showInlinePagination = true,
  });

  final RequisicaoTab activeTab;
  final ProductListState productState;
  final RequisicaoState requisicaoState;
  final bool canAddProducts;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefreshProducts;
  final Future<void> Function(int page) onGoToPage;
  final ValueChanged<RequisicaoTab> onTabChanged;
  final ValueChanged<Product> onSelectProduct;
  final ValueChanged<String> onSelectPendingRequisition;
  final ValueChanged<String> onSelectHistoryRequisition;
  final bool showInlinePagination;

  @override
  State<_LeftPane> createState() => _LeftPaneState();
}

class _LeftPaneState extends State<_LeftPane>
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
  void didUpdateWidget(covariant _LeftPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _indexForTab(widget.activeTab);
    if (widget.activeTab != oldWidget.activeTab &&
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
    switch (tab) {
      case RequisicaoTab.produtos:
        return 0;
      case RequisicaoTab.pendentes:
        return 1;
      case RequisicaoTab.historico:
        return 2;
    }
  }

  RequisicaoTab _tabForIndex(int index) {
    switch (index) {
      case 1:
        return RequisicaoTab.pendentes;
      case 2:
        return RequisicaoTab.historico;
      case 0:
      default:
        return RequisicaoTab.produtos;
    }
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
                text:
                    'Pendentes (${widget.requisicaoState.pendingRequisicoes.length})',
              ),
              Tab(
                height: t.minTouchTarget,
                text:
                    'Finalizadas (${widget.requisicaoState.historyRequisicoes.length})',
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
              canAddItems: widget.canAddProducts,
              onSearchChanged: widget.onSearchChanged,
              onRefreshProducts: widget.onRefreshProducts,
              onGoToPage: widget.onGoToPage,
              onSelectProduct: widget.onSelectProduct,
              showPagination: widget.showInlinePagination,
            ),
            RequisicaoTab.pendentes => RequisicaoResumoListTab(
              title: 'Requisições Pendentes',
              subtitle:
                  'Selecione uma requisição pendente para carregar os itens e voltar automaticamente para a tab Produtos.',
              isLoading: widget.requisicaoState.isLoadingLists,
              requisicoes: widget.requisicaoState.pendingRequisicoes,
              activeRequisicaoId: widget.requisicaoState.activeRequisicao?.id,
              emptyTitle: 'Nenhuma requisição pendente',
              emptySubtitle:
                  'Inicie uma nova requisição para criar o registo no backend.',
              emptyIcon: Icons.assignment_outlined,
              onSelect: widget.onSelectPendingRequisition,
            ),
            RequisicaoTab.historico => RequisicaoResumoListTab(
              title: 'Requisições Finalizadas',
              subtitle:
                  'Apenas visualização. Abra um card para consultar a requisição no painel da direita.',
              isLoading: widget.requisicaoState.isLoadingLists,
              requisicoes: widget.requisicaoState.historyRequisicoes,
              activeRequisicaoId: widget.requisicaoState.activeRequisicao?.id,
              emptyTitle: 'Nenhuma requisição finalizada',
              emptySubtitle:
                  'As requisições confirmadas aparecerão aqui automaticamente.',
              emptyIcon: Icons.assignment_outlined,
              onSelect: widget.onSelectHistoryRequisition,
            ),
          },
        ),
      ],
    );
  }
}

class _RightPane extends StatelessWidget {
  const _RightPane({
    required this.state,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
    required this.onEditHeader,
    required this.onEditItem,
    required this.onRemoveItem,
  });

  final RequisicaoState state;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;
  final Future<void> Function() onCancel;
  final Future<void> Function() onEditHeader;
  final ValueChanged<RequisicaoItem> onEditItem;
  final ValueChanged<RequisicaoItem> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final requisicao = state.activeRequisicao;
    final isItemsEditable =
        state.canEditActiveRequisicao && !state.isAddingItem;

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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  requisicao == null
                      ? 'Nova Requisição'
                      : 'Requisição #${requisicao.id}',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              if (state.isLoadingActiveRequisicao ||
                  state.isAddingItem ||
                  state.isUpdatingRequisicao ||
                  state.isApprovingRequisicao ||
                  state.isRejectingRequisicao ||
                  state.isCancellingRequisicao)
                const PharmaButtonLoader(),
            ],
          ),
          SizedBox(height: s.lg),
          if (requisicao == null)
            const Expanded(
              child: _EmptyPane(
                icon: Icons.assignment_outlined,
                title: 'Nenhuma requisição seleccionada',
                subtitle: 'Seleccione uma requisição pendente ou do histórico.',
              ),
            )
          else ...[
            _ActiveStockFlowHeader(
              requisicao: requisicao,
              canEdit:
                  state.canEditActiveRequisicao && !state.isUpdatingRequisicao,
              onEdit: onEditHeader,
            ),
            if ((requisicao.observacao ?? '').trim().isNotEmpty) ...[
              SizedBox(height: s.sm),
              Text(
                requisicao.observacao!,
                style: TextStyle(color: t.textMuted),
              ),
            ],
            if (requisicao.user != null) ...[
              SizedBox(height: s.xs),
              Text(
                'Criada por ${requisicao.user!.nome}',
                style: TextStyle(color: t.textMuted),
              ),
            ],
            SizedBox(height: s.md),
            Expanded(
              child: requisicao.itens.isEmpty
                  ? const _EmptyPane(
                      icon: Icons.playlist_add_outlined,
                      title: 'Carrinho vazio',
                      subtitle: 'Selecione produtos na lista ao lado.',
                    )
                  : _StockFlowItemsTable(
                      items: requisicao.itens,
                      isEditable: isItemsEditable,
                      onEdit: onEditItem,
                      onRemove: onRemoveItem,
                    ),
            ),
          ],
          SizedBox(height: s.md),
          _StockFlowActionFooter(
            state: state,
            onApprove: onApprove,
            onReject: onReject,
            onCancel: onCancel,
          ),
        ],
      ),
    );
  }
}

class _ActiveStockFlowHeader extends StatelessWidget {
  const _ActiveStockFlowHeader({
    required this.requisicao,
    this.canEdit = false,
    this.onEdit,
  });

  final RequisicaoDetalhe requisicao;
  final bool canEdit;
  final Future<void> Function()? onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final routeLabel = stockFlowFormatRouteLabel(
      requisicao.origem,
      requisicao.destino,
    );

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  requisicao.numeroDocumento.isNotEmpty
                      ? 'Documento ${requisicao.numeroDocumento}'
                      : 'Requisição #${requisicao.id}',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (canEdit && onEdit != null)
                IconButton(
                  tooltip: 'Editar cabeçalho',
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: t.iconSm),
                ),
            ],
          ),
          SizedBox(height: s.sm),
          Wrap(
            spacing: s.sm,
            runSpacing: s.sm,
            children: [
              _InfoTag(
                label: requisicao.status.label,
                color: requisicao.status.isEditable
                    ? t.posWarning
                    : t.brandGreen,
              ),
              _InfoTag(label: requisicao.tipo.label, color: t.brandBlue),
              if (routeLabel.isNotEmpty)
                _InfoTag(label: routeLabel, color: t.brandBlue),
              _InfoTag(
                label: 'Data ${stockFlowFormatDate(requisicao.createdAt)}',
                color: t.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockFlowActionFooter extends StatelessWidget {
  const _StockFlowActionFooter({
    required this.state,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
  });

  final RequisicaoState state;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final requisicao = state.activeRequisicao;
    final helperText = switch (requisicao?.status) {
      null => 'Inicie ou seleccione uma requisição para habilitar acções.',
      RequisicaoStatus.pendente =>
        requisicao!.itens.isEmpty
            ? 'Adicione itens para aprovar.'
            : 'Quantidade total: ${stockFlowFormatQuantity(requisicao.quantidadeTotal)}',
      RequisicaoStatus.aprovada => 'Requisição aprovada.',
      RequisicaoStatus.rejeitada => 'Requisição rejeitada.',
      RequisicaoStatus.concluida => 'Requisição finalizada.',
      RequisicaoStatus.cancelada => 'Requisição cancelada.',
    };
    final highlightHelper =
        requisicao?.status == RequisicaoStatus.pendente &&
        requisicao!.itens.isNotEmpty;

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
              color: highlightHelper ? t.textPrimary : t.textMuted,
              fontWeight: highlightHelper ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          if (state.canEditActiveRequisicao) ...[
            SizedBox(height: s.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        state.canCancelActiveRequisicao &&
                            !state.isCancellingRequisicao &&
                            !state.isApprovingRequisicao &&
                            !state.isRejectingRequisicao
                        ? onCancel
                        : null,
                    icon: state.isCancellingRequisicao
                        ? const PharmaButtonLoader()
                        : const Icon(Icons.close_rounded),
                    label: const Text('Cancelar'),
                  ),
                ),
                SizedBox(width: s.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        state.canRejectActiveRequisicao &&
                            !state.isRejectingRequisicao &&
                            !state.isApprovingRequisicao &&
                            !state.isCancellingRequisicao
                        ? onReject
                        : null,
                    icon: state.isRejectingRequisicao
                        ? const PharmaButtonLoader()
                        : const Icon(Icons.block_outlined),
                    label: const Text('Rejeitar'),
                  ),
                ),
                SizedBox(width: s.sm),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed:
                        state.canApproveActiveRequisicao &&
                            !state.isApprovingRequisicao &&
                            !state.isRejectingRequisicao &&
                            !state.isCancellingRequisicao
                        ? onApprove
                        : null,
                    icon: state.isApprovingRequisicao
                        ? const PharmaButtonLoader()
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      state.isApprovingRequisicao
                          ? 'A aprovar...'
                          : 'Aprovar Requisição',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StockFlowItemsTable extends StatelessWidget {
  const _StockFlowItemsTable({
    required this.items,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
  });

  final List<RequisicaoItem> items;
  final bool isEditable;
  final ValueChanged<RequisicaoItem> onEdit;
  final ValueChanged<RequisicaoItem> onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 768) {
          return _StockFlowItemsCardList(
            items: items,
            isEditable: isEditable,
            onEdit: onEdit,
            onRemove: onRemove,
          );
        }

        if (width < 1200) {
          return _StockFlowItemsTabletTable(
            items: items,
            isEditable: isEditable,
            onEdit: onEdit,
            onRemove: onRemove,
          );
        }

        return _StockFlowItemsDesktopTable(
          items: items,
          isEditable: isEditable,
          onEdit: onEdit,
          onRemove: onRemove,
        );
      },
    );
  }
}

class _StockFlowItemsDesktopTable extends StatelessWidget {
  const _StockFlowItemsDesktopTable({
    required this.items,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
  });

  final List<RequisicaoItem> items;
  final bool isEditable;
  final ValueChanged<RequisicaoItem> onEdit;
  final ValueChanged<RequisicaoItem> onRemove;

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
              columnSpacing: s.lg,
              columns: const [
                DataColumn(label: Text('Produto')),
                DataColumn(label: Text('Lote')),
                DataColumn(label: Text('Validade')),
                DataColumn(label: Text('Qtd')),
                DataColumn(label: Text('Ações')),
              ],
              rows: items.map((item) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(width: 260, child: Text(item.produtoNome)),
                    ),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(stockFlowItemLoteNumero(item)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(stockFlowItemLoteValidade(item)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 90,
                        child: Text(stockFlowFormatQuantity(item.quantidade)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: _StockFlowItemActionButtons(
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

class _StockFlowItemsTabletTable extends StatelessWidget {
  const _StockFlowItemsTabletTable({
    required this.items,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
  });

  final List<RequisicaoItem> items;
  final bool isEditable;
  final ValueChanged<RequisicaoItem> onEdit;
  final ValueChanged<RequisicaoItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                t.bgPrimary.withValues(alpha: 0.1),
              ),
              columnSpacing: s.md,
              columns: const [
                DataColumn(label: Text('Produto')),
                DataColumn(label: Text('Lote')),
                DataColumn(label: Text('Qtd')),
                DataColumn(label: Text('Ações')),
              ],
              rows: items.map((item) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(width: 220, child: Text(item.produtoNome)),
                    ),
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: Text(stockFlowItemLoteNumero(item)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 90,
                        child: Text(stockFlowFormatQuantity(item.quantidade)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: _StockFlowItemActionButtons(
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

class _StockFlowItemsCardList extends StatelessWidget {
  const _StockFlowItemsCardList({
    required this.items,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
  });

  final List<RequisicaoItem> items;
  final bool isEditable;
  final ValueChanged<RequisicaoItem> onEdit;
  final ValueChanged<RequisicaoItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        return _StockFlowItemCard(
          item: item,
          isEditable: isEditable,
          onEdit: onEdit,
          onRemove: onRemove,
        );
      },
    );
  }
}

class _StockFlowItemCard extends StatelessWidget {
  const _StockFlowItemCard({
    required this.item,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
  });

  final RequisicaoItem item;
  final bool isEditable;
  final ValueChanged<RequisicaoItem> onEdit;
  final ValueChanged<RequisicaoItem> onRemove;

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
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: s.sm),
          Wrap(
            spacing: s.md,
            runSpacing: s.sm,
            children: [
              _StockFlowItemInfo(
                label: 'Lote',
                value: stockFlowItemLoteNumero(item),
              ),
              _StockFlowItemInfo(
                label: 'Validade',
                value: stockFlowItemLoteValidade(item),
              ),
              _StockFlowItemInfo(
                label: 'Quantidade',
                value: stockFlowFormatQuantity(item.quantidade),
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
                style: OutlinedButton.styleFrom(foregroundColor: t.posDanger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockFlowItemInfo extends StatelessWidget {
  const _StockFlowItemInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return RichText(
      text: TextSpan(
        style: TextStyle(color: t.textMuted, fontSize: 12),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _StockFlowItemActionButtons extends StatelessWidget {
  const _StockFlowItemActionButtons({
    required this.item,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
    this.showDetailsButton = false,
  });

  final RequisicaoItem item;
  final bool isEditable;
  final ValueChanged<RequisicaoItem> onEdit;
  final ValueChanged<RequisicaoItem> onRemove;
  final bool showDetailsButton;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDetailsButton)
          IconButton(
            icon: Icon(Icons.info_outline_rounded, size: t.iconSm),
            onPressed: () => _showStockFlowItemDetails(context, item),
            tooltip: 'Ver detalhes',
          ),
        IconButton(
          icon: Icon(Icons.edit_outlined, size: t.iconSm),
          onPressed: isEditable ? () => onEdit(item) : null,
          tooltip: 'Editar item',
        ),
        IconButton(
          icon: Icon(Icons.delete_outline_rounded, size: t.iconSm),
          onPressed: isEditable ? () => onRemove(item) : null,
          color: t.posDanger,
          tooltip: 'Remover item',
        ),
      ],
    );
  }
}

Future<void> _showStockFlowItemDetails(
  BuildContext context,
  RequisicaoItem item,
) {
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
              _DialogDetailRow(
                label: 'Lote',
                value: stockFlowItemLoteNumero(item),
              ),
              SizedBox(height: s.sm),
              _DialogDetailRow(
                label: 'Validade',
                value: stockFlowItemLoteValidade(item),
              ),
              SizedBox(height: s.sm),
              _DialogDetailRow(
                label: 'Quantidade',
                value: stockFlowFormatQuantity(item.quantidade),
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
  const _DialogDetailRow({required this.label, required this.value});

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
            style: TextStyle(color: t.textMuted, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
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
        style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600),
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
                fontSize: 16,
              ),
            ),
            SizedBox(height: s.sm),
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

class _EditStockFlowItemDialog extends StatefulWidget {
  const _EditStockFlowItemDialog({required this.item});

  final RequisicaoItem item;

  @override
  State<_EditStockFlowItemDialog> createState() =>
      _EditStockFlowItemDialogState();
}

class _EditStockFlowItemDialogState extends State<_EditStockFlowItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantidadeController;

  @override
  void initState() {
    super.initState();
    _quantidadeController = TextEditingController(
      text: stockFlowFormatQuantity(widget.item.quantidade),
    );
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final quantidade = double.parse(
      _quantidadeController.text.trim().replaceAll(',', '.'),
    );
    Navigator.of(context).pop(quantidade);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final t = context.pharmaTokens;

    return PharmaResponsiveDialog(
      title: const Text('Editar Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ItemDialogProductHeader(
              productName: widget.item.produtoNome,
              description:
                  'Revise a quantidade deste item mantendo os dados do lote associados a esta requisição.',
              metadata: [
                'Lote ${stockFlowItemLoteNumero(widget.item)}',
                'Validade ${stockFlowItemLoteValidade(widget.item)}',
              ],
            ),
            SizedBox(height: s.lg),
            TextFormField(
              controller: _quantidadeController,
              decoration: const InputDecoration(
                labelText: 'Quantidade *',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final normalized = value?.trim().replaceAll(',', '.') ?? '';
                final parsed = double.tryParse(normalized);
                if (parsed == null || parsed <= 0) {
                  return 'Informe uma quantidade válida';
                }
                return null;
              },
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
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _RequisicaoLoteDialog extends ConsumerStatefulWidget {
  const _RequisicaoLoteDialog({required this.product, required this.tipo});

  final Product product;
  final RequisicaoTipo tipo;

  @override
  ConsumerState<_RequisicaoLoteDialog> createState() =>
      _RequisicaoLoteDialogState();
}

class _RequisicaoLoteDialogState extends ConsumerState<_RequisicaoLoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _loteController;
  late final TextEditingController _dataValidadeController;
  late final TextEditingController _quantidadeController;
  List<ProdutoLoteDisponivel> _lotes = const [];
  bool _loadingLotes = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loteController = TextEditingController(text: widget.product.lote ?? '');
    _dataValidadeController = TextEditingController(
      text: widget.product.dataValidade != null
          ? stockFlowFormatDate(widget.product.dataValidade!)
          : stockFlowFormatDate(DateTime(2027, 12, 31)),
    );
    _quantidadeController = TextEditingController(text: '1');
    _loadLotes();
  }

  Future<void> _loadLotes() async {
    try {
      final lotes = await ref
          .read(requisicaoRepositoryProvider)
          .listarLotesProduto(widget.product.id);
      if (!mounted) return;
      setState(() {
        _lotes = lotes;
        _loadingLotes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingLotes = false;
      });
    }
  }

  @override
  void dispose() {
    _loteController.dispose();
    _dataValidadeController.dispose();
    _quantidadeController.dispose();
    super.dispose();
  }

  ProdutoLoteDisponivel? _findLote(String numeroLote, DateTime dataValidade) {
    final normalized = numeroLote.trim().toLowerCase();
    final exactMatches = _lotes.where(
      (lote) =>
          lote.numeroLote.trim().toLowerCase() == normalized &&
          stockFlowSameCalendarDay(lote.dataValidade, dataValidade),
    );
    if (exactMatches.isNotEmpty) {
      return exactMatches.first;
    }

    final byNumero = _lotes
        .where((lote) => lote.numeroLote.trim().toLowerCase() == normalized)
        .toList();
    if (byNumero.length == 1) {
      return byNumero.first;
    }

    return null;
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final initialDate =
        stockFlowParseDateInput(_dataValidadeController.text.trim()) ??
        widget.product.dataValidade ??
        now.add(const Duration(days: 365));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );
    if (pickedDate == null) {
      return;
    }
    _dataValidadeController.text = stockFlowFormatDate(pickedDate);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final numeroLote = _loteController.text.trim();
    final dataValidade = stockFlowParseDateInput(
      _dataValidadeController.text.trim(),
    );
    if (dataValidade == null) {
      return;
    }

    final quantidade = double.parse(
      _quantidadeController.text.trim().replaceAll(',', '.'),
    );

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      var matchedLote = _findLote(numeroLote, dataValidade);
      String? loteId = matchedLote?.id;

      if (loteId == null && widget.tipo == RequisicaoTipo.entrada) {
        final fornecedorId = ref
            .read(requisicaoProvider)
            .activeRequisicao
            ?.fornecedorId;
        if (fornecedorId == null || fornecedorId.trim().isEmpty) {
          setState(() {
            _error =
                'Associe um fornecedor à requisição antes de registar um novo lote.';
          });
          return;
        }

        final created = await ref
            .read(requisicaoProvider.notifier)
            .criarLote(
              produtoId: widget.product.id,
              fornecedorId: fornecedorId,
              numeroLote: numeroLote,
              dataValidade: dataValidade,
            );
        if (!mounted) {
          return;
        }
        if (created == null) {
          return;
        }
        loteId = created.loteId;
      }

      if (loteId == null) {
        setState(() {
          _error = 'Lote não encontrado para este produto.';
        });
        return;
      }

      matchedLote ??= _lotes.where((lote) => lote.id == loteId).firstOrNull;

      if (widget.tipo.isOutbound &&
          matchedLote != null &&
          quantidade > matchedLote.quantidadeAtual) {
        setState(() {
          _error = 'Quantidade superior ao stock do lote.';
        });
        return;
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        RequisicaoItemDraft(
          produtoId: widget.product.id,
          produtoNome: widget.product.nome,
          quantidadeSolicitada: quantidade,
          loteId: loteId,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isBusy = _loadingLotes || _submitting;

    return PharmaResponsiveDialog(
      title: const Text('Adicionar Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ItemDialogProductHeader(
              productName: widget.product.nome,
              description: widget.tipo == RequisicaoTipo.entrada
                  ? 'Informe os dados do lote para entrada do produto e registo documental da movimentação.'
                  : 'Selecione o lote e a quantidade do produto para movimentar com segurança.',
              metadata: [
                if ((widget.product.lote ?? '').trim().isNotEmpty)
                  'Lote sugerido ${widget.product.lote!.trim()}',
                if (widget.product.dataValidade != null)
                  'Validade ${stockFlowFormatDate(widget.product.dataValidade!)}',
              ],
            ),
            SizedBox(height: s.lg),
            if (_loadingLotes)
              Padding(
                padding: EdgeInsets.only(bottom: s.md),
                child: const LinearProgressIndicator(),
              ),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: t.posDanger)),
              SizedBox(height: s.sm),
            ],
            TextFormField(
              controller: _loteController,
              decoration: const InputDecoration(
                labelText: 'Lote',
                hintText: 'Ex.: LOTE-2026-001',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o número do lote'
                  : null,
            ),
            SizedBox(height: s.md),
            TextFormField(
              controller: _dataValidadeController,
              keyboardType: TextInputType.datetime,
              inputFormatters: [_StockFlowDateTextInputFormatter()],
              decoration: InputDecoration(
                labelText: 'Prazo de validade',
                hintText: 'DD/MM/AAAA',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: isBusy ? null : _pickExpiryDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  tooltip: 'Selecionar data',
                ),
              ),
              onEditingComplete: () {
                _dataValidadeController.text = stockFlowNormalizeDateInput(
                  _dataValidadeController.text,
                );
              },
              validator: (value) {
                final normalized = value?.trim() ?? '';
                if (normalized.isEmpty) {
                  return 'Informe o prazo de validade';
                }
                if (stockFlowParseDateInput(normalized) == null) {
                  return 'Use o formato DD/MM/AAAA';
                }
                return null;
              },
            ),
            SizedBox(height: s.md),
            TextFormField(
              controller: _quantidadeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Quantidade',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final parsed = double.tryParse(
                  (value ?? '').replaceAll(',', '.'),
                );
                if (parsed == null || parsed <= 0) {
                  return 'Informe uma quantidade válida';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: isBusy ? null : _submit,
          child: _submitting
              ? const PharmaButtonLoader()
              : const Text('Adicionar'),
        ),
      ],
    );
  }
}

class _ItemDialogProductHeader extends StatelessWidget {
  const _ItemDialogProductHeader({
    required this.productName,
    required this.description,
    this.metadata = const [],
  });

  final String productName;
  final String description;
  final List<String> metadata;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.bgPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produto',
            style: theme.textTheme.labelMedium?.copyWith(
              color: t.brandBlue,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: s.xs),
          Text(
            productName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          SizedBox(height: s.xs),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(color: t.textSecondary),
          ),
          if (metadata.isNotEmpty) ...[
            SizedBox(height: s.sm),
            Wrap(
              spacing: s.sm,
              runSpacing: s.sm,
              children: [
                for (final item in metadata)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: s.sm,
                      vertical: s.xs,
                    ),
                    decoration: BoxDecoration(
                      color: t.card.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(t.radiusMd),
                      border: Border.all(
                        color: t.border.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Text(
                      item,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
