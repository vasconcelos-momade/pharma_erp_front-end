import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/feedback/pharma_snackbar.dart';
import '../../../../shared/widgets/layout/module_page_frame.dart';
import '../../../pharmacy/products/domain/entities/product.dart';
import '../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../domain/entities/requisicao.dart';
import '../providers/requisicao_provider.dart';
import '../widgets/criar_requisicao_dialog.dart';
import '../widgets/requisicao_products_tab.dart';
import '../widgets/requisicao_resumo_card.dart';
import '../widgets/requisicao_stock_flow_view.dart';

String _formatMoney(num value) => '${value.toStringAsFixed(2)} MT';

String _formatQuantity(num value) {
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

String _formatDisplayDate(dynamic value) {
  if (value is DateTime) {
    return _formatDate(value);
  }
  final normalized = value?.toString().trim() ?? '';
  if (normalized.isEmpty) {
    return '-';
  }
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) {
    return normalized;
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshPage() async {
    await ref.read(requisicaoProductListProvider.notifier).refreshCurrentPage();
    if (_isCompraMode) {
      await ref.read(requisicaoCompraProvider.notifier).refreshLists();
    } else {
      await ref.read(requisicaoProvider.notifier).refreshLists();
    }
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
        await ref.read(requisicaoCompraProvider.notifier).startRequisition(
              fornecedorId: result.fornecedorId!,
              numeroDocumento: result.numeroDocumento!,
              tipo: RequisicaoTipo.compra,
            );
        if (_selectedTipo != 'compra') {
          _changeTipo('compra');
        }
      case CriarRequisicaoModalTipo.entrada:
        await ref.read(requisicaoProvider.notifier).startRequisition(
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
        await ref.read(requisicaoProvider.notifier).startRequisition(
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
      PharmaSnackbar.showError(
        context,
        'Inicie ou seleccione uma requisição pendente antes de adicionar itens.',
      );
      return;
    }

    final draft = await showDialog<RequisicaoCompraItemDraft>(
      context: context,
      builder: (_) => _RequisicaoItemDialog(product: product),
    );

    if (!mounted || draft == null) {
      return;
    }

    await ref.read(requisicaoCompraProvider.notifier).addCompraItemToActiveRequisition(
          draft: draft,
        );
  }

  Future<void> _handleEditCompraItem(RequisicaoItem item) async {
    final compraState = ref.read(requisicaoCompraProvider);
    if (!compraState.canEditActiveRequisicao) {
      PharmaSnackbar.showError(
        context,
        'Seleccione uma requisição pendente antes de editar itens.',
      );
      return;
    }

    final draft = await showDialog<RequisicaoCompraItemDraft>(
      context: context,
      builder: (_) => _RequisicaoItemDialog(item: item),
    );

    if (!mounted || draft == null) {
      return;
    }

    await ref.read(requisicaoCompraProvider.notifier).updateCompraItemInActiveRequisition(
          item: item,
          draft: draft,
        );
  }

  List<Widget> _buildTopActions({required bool isCreating}) {
    return [
      SizedBox(
        width: 360,
        child: SegmentedButton<String>(
          segments: const [
            ButtonSegment<String>(
              value: 'compra',
              icon: Icon(Icons.shopping_cart_outlined),
              label: Text('Compra'),
            ),
            ButtonSegment<String>(
              value: 'entrada',
              icon: Icon(Icons.arrow_downward_rounded),
              label: Text('Entrada'),
            ),
            ButtonSegment<String>(
              value: 'saida',
              icon: Icon(Icons.arrow_upward_rounded),
              label: Text('Saída'),
            ),
          ],
          selected: {_selectedTipo},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              _changeTipo(selection.first);
            }
          },
        ),
      ),
      OutlinedButton.icon(
        onPressed: _refreshPage,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Atualizar'),
      ),
      FilledButton.icon(
        onPressed: isCreating ? null : _criarRequisicao,
        icon: isCreating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded),
        label: const Text('Criar Requisição'),
      ),
    ];
  }

  Future<void> _confirmRemoveCompraItem(RequisicaoItem item) async {
    final t = context.pharmaTokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar remoção'),
        content: Text(
          'Deseja remover o item "${item.produtoNome}" da requisição?\n\n'
          'Lote: ${item.numeroLote?.isNotEmpty == true ? item.numeroLote : '—'}\n'
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

    await ref.read(requisicaoCompraProvider.notifier).removeItemFromActiveRequisition(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final compraState = ref.watch(requisicaoCompraProvider);
    final requisicaoState = ref.watch(requisicaoProvider);
    final isCreating = compraState.isCreatingRequisicao ||
        requisicaoState.isCreatingRequisicao;

    if (!_isCompraMode) {
      return ModulePageFrame(
        actions: _buildTopActions(isCreating: isCreating),
        child: RequisicaoStockFlowView(
          searchController: _searchController,
          tipo: _stockTipo,
        ),
      );
    }

    final s = context.spacing;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width <= 920;
    final productState = ref.watch(requisicaoProductListProvider);
    final productController = ref.read(requisicaoProductListProvider.notifier);

    // Sync search controller without modifying during build
    ref.listen<ProductListState>(requisicaoProductListProvider, (previous, next) {
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
      if (previous?.errorMessage != next.errorMessage && next.errorMessage != null) {
        PharmaSnackbar.showError(context, next.errorMessage!);
      }
      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        PharmaSnackbar.showSuccess(context, next.successMessage!);
      }
    });

    return ModulePageFrame(
      actions: _buildTopActions(isCreating: isCreating),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            SizedBox(
              height: 520,
              child: _LeftPane(
                activeTab: compraState.activeTab,
                productState: productState,
                pendingRequisicoes: compraState.pendingRequisicoes,
                historyRequisicoes: compraState.historyRequisicoes,
                isLoadingLists: compraState.isLoadingLists,
                activeRequisicaoId: compraState.activeRequisicao?.id,
                searchController: _searchController,
                canAddItems: compraState.canEditActiveRequisicao &&
                    !compraState.isAddingItem &&
                    !compraState.isApprovingRequisicao,
                onSearchChanged: productController.onSearchChanged,
                onRefreshProducts: productController.refreshCurrentPage,
                onGoToPage: productController.goToPage,
                onTabChanged: ref.read(requisicaoCompraProvider.notifier).setActiveTab,
                onSelectProduct: _handleProduct,
                onSelectPendingPurchase:
                    ref.read(requisicaoCompraProvider.notifier).selectPendingRequisition,
                onSelectFinalizedPurchase:
                    ref.read(requisicaoCompraProvider.notifier).selectHistoryRequisition,
              ),
            ),
            SizedBox(height: s.lg),
            _RightPane(
              state: compraState,
              onConfirm: ref.read(requisicaoCompraProvider.notifier).approveActiveRequisition,
              onEditItem: _handleEditCompraItem,
              onRemoveItem: _confirmRemoveCompraItem,
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
                      pendingRequisicoes: compraState.pendingRequisicoes,
                      historyRequisicoes: compraState.historyRequisicoes,
                      isLoadingLists: compraState.isLoadingLists,
                      activeRequisicaoId: compraState.activeRequisicao?.id,
                      searchController: _searchController,
                      canAddItems: compraState.canEditActiveRequisicao &&
                          !compraState.isAddingItem &&
                          !compraState.isApprovingRequisicao,
                      onSearchChanged: productController.onSearchChanged,
                      onRefreshProducts: productController.refreshCurrentPage,
                      onGoToPage: productController.goToPage,
                      onTabChanged: ref.read(requisicaoCompraProvider.notifier).setActiveTab,
                      onSelectProduct: _handleProduct,
                      onSelectPendingPurchase:
                          ref.read(requisicaoCompraProvider.notifier).selectPendingRequisition,
                      onSelectFinalizedPurchase:
                          ref.read(requisicaoCompraProvider.notifier).selectHistoryRequisition,
                    ),
                  ),
                  SizedBox(width: s.lg),
                  Expanded(
                    flex: 5,
                    child: _RightPane(
                      state: compraState,
                      onConfirm:
                          ref.read(requisicaoCompraProvider.notifier).approveActiveRequisition,
                      onEditItem: _handleEditCompraItem,
                      onRemoveItem: _confirmRemoveCompraItem,
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
    required this.pendingRequisicoes,
    required this.historyRequisicoes,
    required this.isLoadingLists,
    required this.activeRequisicaoId,
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

  final RequisicaoTab activeTab;
  final ProductListState productState;
  final List<RequisicaoResumo> pendingRequisicoes;
  final List<RequisicaoResumo> historyRequisicoes;
  final bool isLoadingLists;
  final String? activeRequisicaoId;
  final TextEditingController searchController;
  final bool canAddItems;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefreshProducts;
  final Future<void> Function(int page) onGoToPage;
  final ValueChanged<RequisicaoTab> onTabChanged;
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
            onTap: (index) => widget.onTabChanged(_tabForIndex(index)),
            labelColor: t.textPrimary,
            unselectedLabelColor: t.textMuted,
            indicatorColor: t.brandBlue,
            dividerColor: Colors.transparent,
            tabs: [
              const Tab(text: 'Produtos'),
              Tab(text: 'Pendentes (${widget.pendingRequisicoes.length})'),
              Tab(text: 'Finalizadas (${widget.historyRequisicoes.length})'),
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
                onRefreshProducts: widget.onRefreshProducts,
                onGoToPage: widget.onGoToPage,
                onSelectProduct: widget.onSelectProduct,
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

class _RightPane extends StatelessWidget {
  const _RightPane({
    required this.state,
    required this.onConfirm,
    required this.onEditItem,
    required this.onRemoveItem,
  });

  final RequisicaoState state;
  final Future<void> Function() onConfirm;
  final Future<void> Function(RequisicaoItem item) onEditItem;
  final Future<void> Function(RequisicaoItem item) onRemoveItem;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final activeRequisicao = state.activeRequisicao;

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
                  activeRequisicao == null
                      ? 'Nova Requisição'
                      : 'Requisição #${activeRequisicao.id}',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              if (state.isLoadingActiveRequisicao ||
                  state.isAddingItem ||
                  state.isApprovingRequisicao)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          SizedBox(height: s.lg),
          if (activeRequisicao == null)
            const Expanded(
              child: _EmptyPane(
                icon: Icons.shopping_cart_outlined,
                title: 'Nenhuma requisição ativa',
                subtitle: 'Inicie uma requisição para adicionar produtos.',
              ),
            )
          else ...[
            _ActivePurchaseHeader(purchase: activeRequisicao),
            SizedBox(height: s.md),
            Expanded(
              child: activeRequisicao.items.isEmpty
                  ? const _EmptyPane(
                      icon: Icons.playlist_add_outlined,
                      title: 'Carrinho vazio',
                      subtitle: 'Selecione produtos na lista ao lado.',
                    )
                  : _PurchaseItemsTable(
                      items: activeRequisicao.items,
                      isEditable: activeRequisicao.status.isEditable,
                      onEdit: onEditItem,
                      onRemove: onRemoveItem,
                    ),
            ),
          ],
          SizedBox(height: s.md),
          _ConfirmFooter(
            canConfirm: state.canApproveActiveRequisicao,
            isLoading: state.isApprovingRequisicao,
            activeRequisicao: activeRequisicao,
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
                    DataCell(SizedBox(width: 150, child: Text(item.numeroLote ?? '-'))),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(_formatDisplayDate(item.dataValidade)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(_formatMoney(item.precoCompra ?? 0)),
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
                        child: Text(_formatMoney(item.subtotal ?? 0)),
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
                      SizedBox(width: 140, child: Text(item.numeroLote ?? '-')),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(_formatMoney(item.precoCompra ?? 0)),
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
                        child: Text(_formatMoney(item.subtotal ?? 0)),
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
              _PurchaseItemInfo(label: 'Lote', value: item.numeroLote ?? '-'),
              _PurchaseItemInfo(
                label: 'Validade',
                value: _formatDisplayDate(item.dataValidade),
              ),
              _PurchaseItemInfo(
                label: 'Preço compra',
                value: _formatMoney(item.precoCompra ?? 0),
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
                value: _formatMoney(item.subtotal ?? 0),
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

Future<void> _showPurchaseItemDetails(BuildContext context, RequisicaoItem item) {
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
              _DialogDetailRow(label: 'Lote', value: item.numeroLote ?? '-'),
              SizedBox(height: s.sm),
              _DialogDetailRow(
                label: 'Validade',
                value: _formatDisplayDate(item.dataValidade),
              ),
              SizedBox(height: s.sm),
              _DialogDetailRow(
                label: 'Preço compra',
                value: _formatMoney(item.precoCompra ?? 0),
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
                value: _formatMoney(item.subtotal ?? 0),
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

  final RequisicaoDetalhe purchase;

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
                : 'Requisição #${purchase.id}',
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
              _InfoTag(label: 'Fornecedor ${purchase.fornecedorNome ?? 'N/A'}', color: t.brandBlue),
              _InfoTag(label: 'Data ${_formatDate(purchase.createdAt)}', color: t.textMuted),
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
    required this.activeRequisicao,
    required this.onConfirm,
  });

  final bool canConfirm;
  final bool isLoading;
  final RequisicaoDetalhe? activeRequisicao;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final helperText = switch (activeRequisicao?.status) {
      null => 'Inicie uma requisição para habilitar ações.',
      RequisicaoStatus.pendente => activeRequisicao!.items.isEmpty
          ? 'Adicione itens para confirmar.'
          : 'Total: ${_formatMoney((activeRequisicao!.total ?? 0))}',
      RequisicaoStatus.aprovada => 'Requisição aprovada.',
      RequisicaoStatus.rejeitada => 'Requisição rejeitada.',
      RequisicaoStatus.concluida => 'Requisição finalizada.',
      RequisicaoStatus.cancelada => 'Requisição cancelada.',
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
              color: activeRequisicao?.status == RequisicaoStatus.pendente &&
                      activeRequisicao!.items.isNotEmpty
                  ? t.textPrimary
                  : t.textMuted,
              fontWeight: activeRequisicao?.status == RequisicaoStatus.pendente &&
                      activeRequisicao!.items.isNotEmpty
                  ? FontWeight.w700
                  : FontWeight.normal,
            ),
          ),
          SizedBox(height: s.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: activeRequisicao != null ? () {} : null,
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
                  label: Text(
                    isLoading ? 'A confirmar...' : 'Confirmar Requisição',
                  ),
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

class _RequisicaoItemDialog extends StatefulWidget {
  const _RequisicaoItemDialog({
    this.product,
    this.item,
  }) : assert(product != null || item != null);

  final Product? product;
  final RequisicaoItem? item;

  bool get isEditing => item != null;
  String get productName => item?.produtoNome ?? product!.nome;
  String get productId => item?.produtoId ?? product!.id;

  @override
  State<_RequisicaoItemDialog> createState() => _RequisicaoItemDialogState();
}

class _RequisicaoItemDialogState extends State<_RequisicaoItemDialog> {
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
      text: widget.item?.precoCompra != null
          ? widget.item!.precoCompra!.toStringAsFixed(2)
          : '',
    );
    _precoVendaController = TextEditingController(
      text: widget.item?.precoVenda != null
          ? widget.item!.precoVenda!.toStringAsFixed(2)
          : '',
    );
    _dataValidadeController = TextEditingController(
      text: widget.item?.dataValidade != null
          ? _formatDate(widget.item!.dataValidade!)
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
      RequisicaoCompraItemDraft(
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
