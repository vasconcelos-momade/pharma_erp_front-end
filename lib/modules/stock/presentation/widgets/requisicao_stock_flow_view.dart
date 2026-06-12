import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/feedback/pharma_snackbar.dart';
import '../../../pharmacy/products/domain/entities/product.dart';
import '../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../domain/entities/fornecedor.dart';
import '../../domain/entities/requisicao.dart';
import '../../data/repositories/requisicao_repository_impl.dart';
import '../providers/fornecedor_provider.dart';
import '../providers/requisicao_provider.dart';
import 'requisicao_products_tab.dart';

String stockFlowFormatQuantity(num value) {
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

String stockFlowFormatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

String stockFlowFormatRouteLabel(String? origem, String? destino) {
  final from = (origem == null || origem.trim().isEmpty) ? 'Sem origem' : origem;
  final to = (destino == null || destino.trim().isEmpty) ? 'Sem destino' : destino;
  return '$from -> $to';
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

class _RequisicaoStockFlowViewState extends ConsumerState<RequisicaoStockFlowView> {
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
      PharmaSnackbar.showError(
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

    await ref.read(requisicaoProvider.notifier).addItemToActiveRequisition(
          draft: draft,
        );
  }

  Future<void> _approveRequisition() async {
    final state = ref.read(requisicaoProvider);
    if (!state.canApproveActiveRequisicao) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aprovar requisição'),
        content: const Text(
          'A aprovação valida a requisição e regista os movimentos documentais. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Aprovar'),
          ),
        ],
      ),
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

    final t = context.pharmaTokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rejeitar requisição'),
        content: const Text('Deseja rejeitar a requisição activa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: t.posDanger),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
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

    final t = context.pharmaTokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar requisição'),
        content: const Text('Deseja cancelar a requisição activa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: t.posDanger),
            child: const Text('Cancelar requisição'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await ref.read(requisicaoProvider.notifier).cancelActiveRequisition();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width <= 920;
    final productState = ref.watch(requisicaoProductListProvider);
    final requisicaoState = ref.watch(requisicaoProvider);
    final productController = ref.read(requisicaoProductListProvider.notifier);
    final canAddProducts = requisicaoState.canEditActiveRequisicao &&
        !requisicaoState.isAddingItem &&
        !requisicaoState.isApprovingRequisicao &&
        !requisicaoState.isRejectingRequisicao &&
        !requisicaoState.isCancellingRequisicao;
    final requisicaoController = ref.read(requisicaoProvider.notifier);

    // Use a listener to sync search controller without modifying during build
    ref.listen<ProductListState>(requisicaoProductListProvider, (previous, next) {
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
      if (previous?.errorMessage != next.errorMessage && next.errorMessage != null) {
        PharmaSnackbar.showError(context, next.errorMessage!);
      }
      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        PharmaSnackbar.showSuccess(context, next.successMessage!);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          if (isMobile) ...[
            SizedBox(
              height: 560,
              child: _LeftPane(
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
                onSelectPendingRequisition:
                    requisicaoController.selectPendingRequisition,
                onSelectHistoryRequisition:
                    requisicaoController.selectHistoryRequisition,
              ),
            ),
            SizedBox(height: s.lg),
            _RightPane(
              state: requisicaoState,
              onApprove: _approveRequisition,
              onReject: _rejectRequisition,
              onCancel: _cancelRequisition,
              onRemoveItem: (itemId) => ref
                  .read(requisicaoProvider.notifier)
                  .removeItemFromActiveRequisition(itemId),
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
                      onSelectPendingRequisition:
                          requisicaoController.selectPendingRequisition,
                      onSelectHistoryRequisition:
                          requisicaoController.selectHistoryRequisition,
                    ),
                  ),
                  SizedBox(width: s.lg),
                  Expanded(
                    flex: 5,
                    child: _RightPane(
                      state: requisicaoState,
                      onApprove: _approveRequisition,
                      onReject: _rejectRequisition,
                      onCancel: _cancelRequisition,
                      onRemoveItem: (itemId) => ref
                          .read(requisicaoProvider.notifier)
                          .removeItemFromActiveRequisition(itemId),
                    ),
                  ),
                ],
              ),
            ),
      ],
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
            onTap: (index) => widget.onTabChanged(_tabForIndex(index)),
            labelColor: t.textPrimary,
            unselectedLabelColor: t.textMuted,
            indicatorColor: t.brandBlue,
            dividerColor: Colors.transparent,
            tabs: [
              const Tab(text: 'Produtos'),
              Tab(
                text:
                    'Pendentes (${widget.requisicaoState.pendingRequisicoes.length})',
              ),
              Tab(
                text:
                    'Histórico (${widget.requisicaoState.historyRequisicoes.length})',
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
              ),
            RequisicaoTab.pendentes => _RequisicaoListTab(
                title: 'Requisições pendentes',
                emptyTitle: 'Nenhuma requisição pendente',
                emptySubtitle:
                    'Inicie uma requisição para criar o documento.',
                requisicoes: widget.requisicaoState.pendingRequisicoes,
                activeRequisicaoId: widget.requisicaoState.activeRequisicao?.id,
                isLoading: widget.requisicaoState.isLoadingLists,
                onSelect: widget.onSelectPendingRequisition,
              ),
            RequisicaoTab.historico => _RequisicaoListTab(
                title: 'Histórico de requisições',
                emptyTitle: 'Nenhuma requisição no histórico',
                emptySubtitle:
                    'Requisições aprovadas, rejeitadas ou canceladas aparecem aqui.',
                requisicoes: widget.requisicaoState.historyRequisicoes,
                activeRequisicaoId: widget.requisicaoState.activeRequisicao?.id,
                isLoading: widget.requisicaoState.isLoadingLists,
                onSelect: widget.onSelectHistoryRequisition,
              ),
          },
        ),
      ],
    );
  }
}

class _RequisicaoListTab extends StatelessWidget {
  const _RequisicaoListTab({
    required this.title,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.requisicoes,
    required this.activeRequisicaoId,
    required this.isLoading,
    required this.onSelect,
  });

  final String title;
  final String emptyTitle;
  final String emptySubtitle;
  final List<RequisicaoResumo> requisicoes;
  final String? activeRequisicaoId;
  final bool isLoading;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    if (isLoading && requisicoes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requisicoes.isEmpty) {
      return _EmptyPane(
        icon: Icons.assignment_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: t.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        SizedBox(height: s.sm),
        Expanded(
          child: ListView.separated(
            itemCount: requisicoes.length,
            separatorBuilder: (_, _) =>
                Divider(color: t.border.withValues(alpha: 0.25)),
            itemBuilder: (context, index) {
              final item = requisicoes[index];
              final isActive = item.id == activeRequisicaoId;
              return ListTile(
                tileColor: isActive
                    ? t.brandBlue.withValues(alpha: 0.08)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: CircleAvatar(
                  backgroundColor: item.status.isPositive
                      ? t.brandGreen.withValues(alpha: 0.14)
                      : item.status == RequisicaoStatus.rejeitada ||
                              item.status == RequisicaoStatus.cancelada
                          ? t.posDanger.withValues(alpha: 0.12)
                          : t.brandBlue.withValues(alpha: 0.14),
                  child: Icon(
                    item.status.isPositive
                        ? Icons.check_circle_outline
                        : item.status == RequisicaoStatus.rejeitada
                            ? Icons.block_outlined
                            : item.status == RequisicaoStatus.cancelada
                                ? Icons.cancel_outlined
                                : Icons.description_outlined,
                    color: item.status.isPositive
                        ? t.brandGreen
                        : item.status == RequisicaoStatus.rejeitada ||
                                item.status == RequisicaoStatus.cancelada
                            ? t.posDanger
                            : t.brandBlue,
                  ),
                ),
                title: Text(
                  item.numeroDocumento,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${stockFlowFormatRouteLabel(item.origem, item.destino)}\n'
                  '${item.status.label} • ${stockFlowFormatQuantity(item.quantidadeTotal)} itens',
                  style: TextStyle(color: t.textMuted),
                ),
                isThreeLine: true,
                onTap: () => onSelect(item.id),
              );
            },
          ),
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
    required this.onRemoveItem,
  });

  final RequisicaoState state;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;
  final Future<void> Function() onCancel;
  final ValueChanged<String> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final requisicao = state.activeRequisicao;

    if (state.isLoadingActiveRequisicao && requisicao == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requisicao == null) {
      return const _EmptyPane(
        icon: Icons.assignment_outlined,
        title: 'Nenhuma requisição seleccionada',
        subtitle: 'Seleccione uma requisição pendente ou do histórico.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusXl),
        border: Border.all(color: t.border.withValues(alpha: 0.35)),
      ),
      padding: EdgeInsets.all(s.lg),
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
                      requisicao.numeroDocumento,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: s.xs),
                    Text(
                      stockFlowFormatRouteLabel(requisicao.origem, requisicao.destino),
                      style: TextStyle(color: t.textMuted),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: requisicao.status),
            ],
          ),
          SizedBox(height: s.md),
          Wrap(
            spacing: s.md,
            runSpacing: s.md,
            children: [
              _InfoCard(
                label: 'Tipo',
                value: requisicao.tipo.label,
              ),
              _InfoCard(
                label: 'Itens',
                value: requisicao.totalItens.toString(),
              ),
              _InfoCard(
                label: 'Quantidade',
                value: stockFlowFormatQuantity(requisicao.quantidadeTotal),
              ),
              _InfoCard(
                label: 'Criada em',
                value: stockFlowFormatDate(requisicao.createdAt),
              ),
            ],
          ),
          if ((requisicao.observacao ?? '').trim().isNotEmpty) ...[
            SizedBox(height: s.md),
            Text(
              'Observação',
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: s.xs),
            Text(
              requisicao.observacao!,
              style: TextStyle(color: t.textMuted),
            ),
          ],
          if (requisicao.user != null) ...[
            SizedBox(height: s.md),
            Text(
              'Criada por ${requisicao.user!.nome}',
              style: TextStyle(color: t.textMuted),
            ),
          ],
          SizedBox(height: s.lg),
          Text(
            'Itens da requisição',
            style: TextStyle(
              color: t.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          SizedBox(height: s.sm),
          Expanded(
            child: requisicao.itens.isEmpty
                ? const _EmptyPane(
                    icon: Icons.playlist_add_outlined,
                    title: 'Sem itens',
                    subtitle:
                        'Seleccione produtos no painel esquerdo para adicionar itens.',
                  )
                : ListView.separated(
                    itemCount: requisicao.itens.length,
                    separatorBuilder: (_, _) => Divider(
                      color: t.border.withValues(alpha: 0.25),
                    ),
                    itemBuilder: (context, index) {
                      final item = requisicao.itens[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              t.brandBlue.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.medication_outlined,
                            color: t.brandBlue,
                          ),
                        ),
                        title: Text(
                          item.produtoNome,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'Quantidade: ${stockFlowFormatQuantity(item.quantidadeSolicitada)}'
                          '${item.lote != null ? ' • Lote: ${item.lote!.numeroLote}' : ''}'
                          '${item.lote?.dataValidade != null ? ' • Validade: ${stockFlowFormatDate(item.lote!.dataValidade!)}' : ''}',
                          style: TextStyle(color: t.textMuted),
                        ),
                        trailing: state.canEditActiveRequisicao
                            ? IconButton(
                                tooltip: 'Remover item',
                                onPressed: state.isAddingItem
                                    ? null
                                    : () => onRemoveItem(item.id),
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: t.posDanger,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
          ),
          if (state.canEditActiveRequisicao) ...[
            SizedBox(height: s.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.canCancelActiveRequisicao &&
                            !state.isCancellingRequisicao &&
                            !state.isApprovingRequisicao &&
                            !state.isRejectingRequisicao
                        ? onCancel
                        : null,
                    icon: state.isCancellingRequisicao
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close_rounded),
                    label: const Text('Cancelar'),
                  ),
                ),
                SizedBox(width: s.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.canRejectActiveRequisicao &&
                            !state.isRejectingRequisicao &&
                            !state.isApprovingRequisicao &&
                            !state.isCancellingRequisicao
                        ? onReject
                        : null,
                    icon: state.isRejectingRequisicao
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.block_outlined),
                    label: const Text('Rejeitar'),
                  ),
                ),
                SizedBox(width: s.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.canApproveActiveRequisicao &&
                            !state.isApprovingRequisicao &&
                            !state.isRejectingRequisicao &&
                            !state.isCancellingRequisicao
                        ? onApprove
                        : null,
                    icon: state.isApprovingRequisicao
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Aprovar'),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      width: 150,
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.bgPrimary.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: t.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          SizedBox(height: s.xs),
          Text(
            value,
            style: TextStyle(
              color: t.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final RequisicaoStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final color = switch (status) {
      RequisicaoStatus.aprovada || RequisicaoStatus.concluida => t.brandGreen,
      RequisicaoStatus.rejeitada => t.posWarning,
      RequisicaoStatus.cancelada => t.posDanger,
      RequisicaoStatus.pendente => t.brandBlue,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: t.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: t.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 320,
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequisicaoLoteDialog extends ConsumerStatefulWidget {
  const _RequisicaoLoteDialog({
    required this.product,
    required this.tipo,
  });

  final Product product;
  final RequisicaoTipo tipo;

  @override
  ConsumerState<_RequisicaoLoteDialog> createState() =>
      _RequisicaoLoteDialogState();
}

class _RequisicaoLoteDialogState extends ConsumerState<_RequisicaoLoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController(text: '1');
  List<ProdutoLoteDisponivel> _lotes = const [];
  ProdutoLoteDisponivel? _selectedLote;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
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
        _selectedLote = lotes.isNotEmpty ? lotes.first : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _selectedLote == null) {
      return;
    }

    Navigator.of(context).pop(
      RequisicaoItemDraft(
        produtoId: widget.product.id,
        produtoNome: widget.product.nome,
        quantidadeSolicitada:
            double.parse(_quantidadeController.text.replaceAll(',', '.')),
        loteId: _selectedLote!.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return AlertDialog(
      title: Text('Adicionar ${widget.product.nome}'),
      content: SizedBox(
        width: 480,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(_error!, style: TextStyle(color: t.posDanger))
                : Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_lotes.isNotEmpty) ...[
                          Text(
                            'Seleccione o lote (FEFO)',
                            style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 180,
                            child: ListView.separated(
                              itemCount: _lotes.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final lote = _lotes[index];
                                final selected = _selectedLote?.id == lote.id;
                                return ListTile(
                                  dense: true,
                                  selected: selected,
                                  title: Text(lote.numeroLote),
                                  subtitle: Text(
                                    'Validade: ${stockFlowFormatDate(lote.dataValidade)} • '
                                    'Stock: ${stockFlowFormatQuantity(lote.quantidadeAtual)}',
                                  ),
                                  onTap: () =>
                                      setState(() => _selectedLote = lote),
                                );
                              },
                            ),
                          ),
                        ],
                        if (_lotes.isEmpty) ...[
                          const Text(
                            'Nenhum lote disponível para este produto. Crie um novo lote!',
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _quantidadeController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          decoration:
                              const InputDecoration(labelText: 'Quantidade'),
                          validator: (value) {
                            final parsed = double.tryParse(
                              (value ?? '').replaceAll(',', '.'),
                            );
                            if (parsed == null || parsed <= 0) {
                              return 'Informe uma quantidade válida';
                            }
                            if (widget.tipo.isOutbound &&
                                _selectedLote != null &&
                                parsed > _selectedLote!.quantidadeAtual) {
                              return 'Quantidade superior ao stock do lote';
                            }
                            return null;
                          },
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
        OutlinedButton.icon(
          onPressed: _loading ? null : _abrirCriarLote,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Novo Lote'),
        ),
        FilledButton(
          onPressed: _loading || _selectedLote == null ? null : _submit,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }

  Future<void> _abrirCriarLote() async {
    final result = await showDialog<CriarLoteResult>(
      context: context,
      builder: (_) => _CriarLoteDialog(productId: widget.product.id),
    );
    if (!mounted || result == null) return;
    await _loadLotes();
    if (!mounted) return;
    final created = _lotes.where((lote) => lote.id == result.loteId);
    setState(() {
      _selectedLote = created.isNotEmpty ? created.first : _selectedLote;
    });
  }
}

class _CriarLoteDialog extends ConsumerStatefulWidget {
  const _CriarLoteDialog({
    required this.productId,
  });

  final String productId;

  @override
  ConsumerState<_CriarLoteDialog> createState() => _CriarLoteDialogState();
}

class _CriarLoteDialogState extends ConsumerState<_CriarLoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numeroLoteController = TextEditingController();
  final _precoCompraController = TextEditingController();
  FornecedorResumo? _selectedFornecedor;
  DateTime? _dataValidade;
  bool _loading = false;

  @override
  void dispose() {
    _numeroLoteController.dispose();
    _precoCompraController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (selected != null) {
      setState(() => _dataValidade = selected);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedFornecedor == null ||
        _dataValidade == null) {
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ref.read(requisicaoProvider.notifier).criarLote(
            produtoId: widget.productId,
            fornecedorId: _selectedFornecedor!.id,
            numeroLote: _numeroLoteController.text.trim(),
            dataValidade: _dataValidade!,
            precoCompra: double.tryParse(_precoCompraController.text.replaceAll(',', '.')),
          );
      if (!mounted) return;
      if (result != null) {
        Navigator.of(context).pop(result);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final fornecedoresAsync = ref.watch(supplierListProvider);

    return AlertDialog(
      title: const Text('Novo Lote'),
      content: SizedBox(
        width: 480,
        child: fornecedoresAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text(
            'Erro ao carregar fornecedores: $error',
            style: TextStyle(color: t.posDanger),
          ),
          data: (fornecedores) => Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<FornecedorResumo>(
                  decoration: const InputDecoration(
                    labelText: 'Fornecedor',
                  ),
                  initialValue: _selectedFornecedor,
                  items: fornecedores
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.nome),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedFornecedor = value),
                  validator: (value) => value == null ? 'Seleccione um fornecedor' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _numeroLoteController,
                  decoration: const InputDecoration(
                    labelText: 'Número do Lote',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Informe o número do lote' : null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data de Validade',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _dataValidade == null
                          ? 'Seleccione a data'
                          : stockFlowFormatDate(_dataValidade!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _precoCompraController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Preço de Compra (opcional)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar Lote'),
        ),
      ],
    );
  }
}
