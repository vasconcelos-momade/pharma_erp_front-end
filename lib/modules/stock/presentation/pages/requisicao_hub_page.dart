import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dimensions.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/responsive/breakpoints.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/layout/module_page_frame.dart';
import '../../../pharmacy/products/domain/entities/product.dart';
import '../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../domain/entities/requisicao.dart';
import '../providers/requisicao_provider.dart';
import '../widgets/criar_requisicao_dialog.dart';
import '../widgets/editar_requisicao_dialog.dart';
import '../widgets/requisicao_compra_item_dialog.dart';
import '../widgets/requisicao_compra_left_pane.dart';
import '../widgets/requisicao_compra_mobile_layout.dart';
import '../widgets/requisicao_compra_right_pane.dart';
import '../widgets/requisicao_stock_flow_view.dart';
import '../widgets/requisicao_top_actions_bar.dart';

class RequisicaoHubPage extends ConsumerStatefulWidget {
  const RequisicaoHubPage({super.key});

  @override
  ConsumerState<RequisicaoHubPage> createState() => _RequisicaoHubPageState();
}

class _RequisicaoHubPageState extends ConsumerState<RequisicaoHubPage> {
  final _searchController = TextEditingController();
  String _selectedTipo = 'compra';

  bool get _isCompraMode => _selectedTipo == 'compra';

  RequisicaoTipo get _stockTipo => switch (_selectedTipo) {
    'entrada' => RequisicaoTipo.entrada,
    'saida' => RequisicaoTipo.saida,
    _ => RequisicaoTipo.compra,
  };

  void _changeTipo(String tipo) {
    if (tipo == _selectedTipo) {
      return;
    }
    setState(() {
      _selectedTipo = tipo;
    });
    if (tipo != 'compra') {
      final stockTipo = switch (tipo) {
        'entrada' => RequisicaoTipo.entrada,
        'saida' => RequisicaoTipo.saida,
        _ => RequisicaoTipo.compra,
      };
      ref.read(requisicaoProvider.notifier).initializeScope(stockTipo);
    }
  }

  String _autoDocumento(String prefix) {
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(requisicaoProductListProvider).query;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(requisicaoProductListProvider.notifier).ensureLoaded(force: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _criarRequisicao() async {
    final initialTab = switch (_selectedTipo) {
      'entrada' => CriarRequisicaoModalTipo.entrada,
      'saida' => CriarRequisicaoModalTipo.saida,
      _ => CriarRequisicaoModalTipo.compra,
    };
    final result = await showDialog<CriarRequisicaoDialogResult>(
      context: context,
      builder: (_) => CriarRequisicaoDialog(initialTipo: initialTab),
    );
    if (!mounted || result == null) {
      return;
    }

    switch (result.tipo) {
      case CriarRequisicaoModalTipo.compra:
        await ref
            .read(requisicaoCompraProvider.notifier)
            .startRequisition(
              fornecedorId: result.fornecedorId!,
              numeroDocumento: result.numeroDocumento!,
              tipo: RequisicaoTipo.compra,
            );
        if (_selectedTipo != 'compra') {
          _changeTipo('compra');
        }
      case CriarRequisicaoModalTipo.entrada:
        await ref
            .read(requisicaoProvider.notifier)
            .startRequisition(
              numeroDocumento: _autoDocumento('ENT'),
              fornecedorId: result.fornecedorId,
              origem: result.origem,
              tipo: RequisicaoTipo.entrada,
              observacao: result.observacao,
            );
        if (_selectedTipo != 'entrada') {
          _changeTipo('entrada');
        }
      case CriarRequisicaoModalTipo.saida:
        await ref
            .read(requisicaoProvider.notifier)
            .startRequisition(
              numeroDocumento: _autoDocumento('SAI'),
              fornecedorId: result.fornecedorId,
              destino: result.destino,
              tipo: RequisicaoTipo.saida,
              observacao: result.observacao,
            );
        if (_selectedTipo != 'saida') {
          _changeTipo('saida');
        }
    }
  }

  Future<void> _handleProduct(Product product) async {
    final compraState = ref.read(requisicaoCompraProvider);
    if (!compraState.canEditActiveRequisicao) {
      PharmaFeedback.error(
        context,
        'Inicie ou seleccione uma requisição pendente antes de adicionar itens.',
      );
      return;
    }

    final draft = await showDialog<RequisicaoCompraItemDraft>(
      context: context,
      builder: (_) => RequisicaoCompraItemDialog(product: product),
    );

    if (!mounted || draft == null) {
      return;
    }

    await ref
        .read(requisicaoCompraProvider.notifier)
        .addCompraItemToActiveRequisition(draft: draft);
  }

  Future<void> _handleEditCompraItem(RequisicaoItem item) async {
    final compraState = ref.read(requisicaoCompraProvider);
    if (!compraState.canEditActiveRequisicao) {
      PharmaFeedback.error(
        context,
        'Seleccione uma requisição pendente antes de editar itens.',
      );
      return;
    }

    final draft = await showDialog<RequisicaoCompraItemDraft>(
      context: context,
      builder: (_) => RequisicaoCompraItemDialog(item: item),
    );

    if (!mounted || draft == null) {
      return;
    }

    await ref
        .read(requisicaoCompraProvider.notifier)
        .updateCompraItemInActiveRequisition(item: item, draft: draft);
  }

  Future<void> _handleEditCompraHeader() async {
    final compraState = ref.read(requisicaoCompraProvider);
    final requisicao = compraState.activeRequisicao;
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
        .read(requisicaoCompraProvider.notifier)
        .updateActiveRequisitionHeader(request: result.toRequest());
  }

  List<Widget> _buildTopActions({required bool isCreating}) {
    return [
      RequisicaoTopActionsBar(
        selectedTipo: _selectedTipo,
        isCreating: isCreating,
        onSelectTipo: _changeTipo,
        onCreate: _criarRequisicao,
      ),
    ];
  }

  Future<void> _confirmRemoveCompraItem(RequisicaoItem item) async {
    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Confirmar remoção',
      message:
          'Deseja remover o item "${item.produtoNome}" da requisição?\n\n'
          'Lote: ${item.numeroLote?.isNotEmpty == true ? item.numeroLote : '—'}\n'
          'Quantidade: ${item.quantidade.toStringAsFixed(item.quantidade.truncateToDouble() == item.quantidade ? 0 : 2)}',
      confirmText: 'Remover',
      cancelText: 'Cancelar',
      destructive: true,
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await ref
        .read(requisicaoCompraProvider.notifier)
        .removeItemFromActiveRequisition(item.id);
  }

  Future<void> _showMobilePurchasePane() {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RequisicaoMobilePurchasePaneScreen(
          onConfirm: ref
              .read(requisicaoCompraProvider.notifier)
              .approveActiveRequisition,
          onEditHeader: _handleEditCompraHeader,
          onEditItem: _handleEditCompraItem,
          onRemoveItem: _confirmRemoveCompraItem,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compraState = ref.watch(requisicaoCompraProvider);
    final requisicaoState = ref.watch(requisicaoProvider);
    final isCreating =
        compraState.isCreatingRequisicao ||
        requisicaoState.isCreatingRequisicao;

    if (!_isCompraMode) {
      return ModulePageFrame(
        scrollable: false,
        actions: _buildTopActions(isCreating: isCreating),
        child: RequisicaoStockFlowView(
          searchController: _searchController,
          tipo: _stockTipo,
        ),
      );
    }

    final s = context.spacing;
    final productState = ref.watch(requisicaoProductListProvider);
    final productController = ref.read(requisicaoProductListProvider.notifier);

    ref.listen<ProductListState>(requisicaoProductListProvider, (
      previous,
      next,
    ) {
      if (_searchController.text != next.query) {
        _searchController.value = TextEditingValue(
          text: next.query,
          selection: TextSelection.collapsed(offset: next.query.length),
        );
      }
    });

    ref.listen<RequisicaoState>(requisicaoCompraProvider, (previous, next) {
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

    final rightPane = RequisicaoCompraRightPane(
      state: compraState,
      onConfirm: ref
          .read(requisicaoCompraProvider.notifier)
          .approveActiveRequisition,
      onEditHeader: _handleEditCompraHeader,
      onEditItem: _handleEditCompraItem,
      onRemoveItem: _confirmRemoveCompraItem,
    );

    return ModulePageFrame(
      scrollable: false,
      actions: _buildTopActions(isCreating: isCreating),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < Breakpoints.tablet;
          final isTablet = width >= Breakpoints.tablet && width < 1180;
          final isWideScreen = width >= AppDimensions.contentMaxWidth;
          final gap = isMobile ? s.md : (isWideScreen ? s.xl : s.lg);

          final leftPane = RequisicaoCompraLeftPane(
            activeTab: compraState.activeTab,
            productState: productState,
            pendingRequisicoes: compraState.pendingRequisicoes,
            historyRequisicoes: compraState.historyRequisicoes,
            isLoadingLists: compraState.isLoadingLists,
            activeRequisicaoId: compraState.activeRequisicao?.id,
            searchController: _searchController,
            canAddItems:
                compraState.canEditActiveRequisicao &&
                !compraState.isAddingItem &&
                !compraState.isApprovingRequisicao,
            onSearchChanged: productController.onSearchChanged,
            onRefreshProducts: productController.refreshCurrentPage,
            onGoToPage: productController.goToPage,
            onTabChanged:
                ref.read(requisicaoCompraProvider.notifier).setActiveTab,
            onSelectProduct: _handleProduct,
            onSelectPendingPurchase: ref
                .read(requisicaoCompraProvider.notifier)
                .selectPendingRequisition,
            onSelectFinalizedPurchase: ref
                .read(requisicaoCompraProvider.notifier)
                .selectHistoryRequisition,
            showInlinePagination: !isMobile,
          );

          if (isMobile) {
            return RequisicaoCompraMobileLayout(
              leftPane: leftPane,
              compraState: compraState,
              productState: productState,
              productController: productController,
              onOpenPurchasePane: _showMobilePurchasePane,
            );
          }

          return RequisicaoCompraDesktopLayout(
            leftPane: leftPane,
            rightPane: rightPane,
            isTablet: isTablet,
            isWideScreen: isWideScreen,
            gap: gap,
          );
        },
      ),
    );
  }
}
