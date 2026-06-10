import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/feedback/pharma_snackbar.dart';
import '../../../../shared/widgets/layout/module_page_frame.dart';
import '../../../pharmacy/products/domain/entities/product.dart';
import '../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../domain/entities/transferencia.dart';
import '../../data/repositories/transferencia_repository_impl.dart';
import '../providers/transferencia_provider.dart';

String _formatQuantity(num value) {
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

class TransferHubPage extends ConsumerStatefulWidget {
  const TransferHubPage({super.key});

  @override
  ConsumerState<TransferHubPage> createState() => _TransferHubPageState();
}

class _TransferHubPageState extends ConsumerState<TransferHubPage> {
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

  Future<void> _refreshPage() async {
    await ref.read(transferenciaProvider.notifier).refreshLists();
    await ref.read(purchaseProductListProvider.notifier).refreshCurrentPage();
  }

  Future<void> _startTransfer() async {
    final result = await showDialog<NovaTransferenciaDialogResult>(
      context: context,
      builder: (_) => const _NovaTransferenciaDialog(),
    );
    if (!mounted || result == null) {
      return;
    }

    await ref.read(transferenciaProvider.notifier).startTransfer(
          numeroDocumento: result.numeroDocumento,
          origem: result.origem,
          destino: result.destino,
          tipo: result.tipo,
          observacao: result.observacao,
        );
  }

  Future<void> _handleProduct(Product product) async {
    final transferState = ref.read(transferenciaProvider);
    if (!transferState.canEditActiveTransfer) {
      PharmaSnackbar.showError(
        context,
        'Inicie ou seleccione uma transferência em rascunho antes de adicionar itens.',
      );
      return;
    }

    final draft = await showDialog<TransferenciaItemDraft>(
      context: context,
      builder: (_) => _TransferenciaLoteDialog(product: product),
    );

    if (!mounted || draft == null) {
      return;
    }

    await ref.read(transferenciaProvider.notifier).addItemToActiveTransfer(
          draft: draft,
        );
  }

  Future<void> _confirmTransfer() async {
    final state = ref.read(transferenciaProvider);
    if (!state.canConfirmActiveTransfer) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar transferência'),
        content: const Text(
          'A confirmação regista os movimentos documentais da transferência. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await ref.read(transferenciaProvider.notifier).confirmActiveTransfer();
  }

  Future<void> _cancelTransfer() async {
    final state = ref.read(transferenciaProvider);
    if (!state.canCancelActiveTransfer) {
      return;
    }

    final t = context.pharmaTokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar transferência'),
        content: const Text('Deseja cancelar a transferência activa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: t.posDanger),
            child: const Text('Cancelar transferência'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await ref.read(transferenciaProvider.notifier).cancelActiveTransfer();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width <= 920;
    final productState = ref.watch(purchaseProductListProvider);
    final transferState = ref.watch(transferenciaProvider);
    final productController = ref.read(purchaseProductListProvider.notifier);
    final transferController = ref.read(transferenciaProvider.notifier);

    if (_searchController.text != productState.query) {
      _searchController.value = TextEditingValue(
        text: productState.query,
        selection: TextSelection.collapsed(offset: productState.query.length),
      );
    }

    ref.listen<TransferenciaState>(transferenciaProvider, (previous, next) {
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
          onPressed: _refreshPage,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
        FilledButton.icon(
          onPressed: transferState.isCreatingTransfer ? null : _startTransfer,
          icon: transferState.isCreatingTransfer
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.swap_horiz_rounded),
          label: const Text('Nova Transferência'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            SizedBox(
              height: 560,
              child: _LeftPane(
                activeTab: transferState.activeTab,
                productState: productState,
                transferState: transferState,
                searchController: _searchController,
                onSearchChanged: productController.onSearchChanged,
                onRefreshProducts: productController.refreshCurrentPage,
                onGoToPage: productController.goToPage,
                onTabChanged: transferController.setActiveTab,
                onSelectProduct: _handleProduct,
                onSelectPendingTransfer: transferController.selectPendingTransfer,
                onSelectConfirmedTransfer:
                    transferController.selectConfirmedTransfer,
              ),
            ),
            SizedBox(height: s.lg),
            _RightPane(
              state: transferState,
              onConfirm: _confirmTransfer,
              onCancel: _cancelTransfer,
              onRemoveItem: (itemId) => ref
                  .read(transferenciaProvider.notifier)
                  .removeItemFromActiveTransfer(itemId),
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
                      activeTab: transferState.activeTab,
                      productState: productState,
                      transferState: transferState,
                      searchController: _searchController,
                      onSearchChanged: productController.onSearchChanged,
                      onRefreshProducts: productController.refreshCurrentPage,
                      onGoToPage: productController.goToPage,
                      onTabChanged: transferController.setActiveTab,
                      onSelectProduct: _handleProduct,
                      onSelectPendingTransfer:
                          transferController.selectPendingTransfer,
                      onSelectConfirmedTransfer:
                          transferController.selectConfirmedTransfer,
                    ),
                  ),
                  SizedBox(width: s.lg),
                  Expanded(
                    flex: 5,
                    child: _RightPane(
                      state: transferState,
                      onConfirm: _confirmTransfer,
                      onCancel: _cancelTransfer,
                      onRemoveItem: (itemId) => ref
                          .read(transferenciaProvider.notifier)
                          .removeItemFromActiveTransfer(itemId),
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
    required this.transferState,
    required this.searchController,
    required this.onSearchChanged,
    required this.onRefreshProducts,
    required this.onGoToPage,
    required this.onTabChanged,
    required this.onSelectProduct,
    required this.onSelectPendingTransfer,
    required this.onSelectConfirmedTransfer,
  });

  final TransferenciaTab activeTab;
  final ProductListState productState;
  final TransferenciaState transferState;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefreshProducts;
  final Future<void> Function(int page) onGoToPage;
  final ValueChanged<TransferenciaTab> onTabChanged;
  final ValueChanged<Product> onSelectProduct;
  final ValueChanged<String> onSelectPendingTransfer;
  final ValueChanged<String> onSelectConfirmedTransfer;

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

  int _indexForTab(TransferenciaTab tab) {
    switch (tab) {
      case TransferenciaTab.produtos:
        return 0;
      case TransferenciaTab.pendentes:
        return 1;
      case TransferenciaTab.concluidas:
        return 2;
    }
  }

  TransferenciaTab _tabForIndex(int index) {
    switch (index) {
      case 1:
        return TransferenciaTab.pendentes;
      case 2:
        return TransferenciaTab.concluidas;
      case 0:
      default:
        return TransferenciaTab.produtos;
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
                    'Pendentes (${widget.transferState.pendingTransfers.length})',
              ),
              Tab(
                text:
                    'Concluídas (${widget.transferState.confirmedTransfers.length})',
              ),
            ],
          ),
        ),
        SizedBox(height: s.md),
        Expanded(
          child: switch (widget.activeTab) {
            TransferenciaTab.produtos => _ProductsTab(
                state: widget.productState,
                searchController: widget.searchController,
                onSearchChanged: widget.onSearchChanged,
                onRefreshProducts: widget.onRefreshProducts,
                onGoToPage: widget.onGoToPage,
                onSelectProduct: widget.onSelectProduct,
              ),
            TransferenciaTab.pendentes => _TransferListTab(
                title: 'Transferências pendentes',
                emptyTitle: 'Nenhuma transferência pendente',
                emptySubtitle:
                    'Inicie uma transferência para criar o documento.',
                transfers: widget.transferState.pendingTransfers,
                activeTransferId: widget.transferState.activeTransfer?.id,
                isLoading: widget.transferState.isLoadingLists,
                onSelect: widget.onSelectPendingTransfer,
              ),
            TransferenciaTab.concluidas => _TransferListTab(
                title: 'Transferências concluídas',
                emptyTitle: 'Nenhuma transferência concluída',
                emptySubtitle:
                    'As transferências concluídas aparecerão aqui.',
                transfers: widget.transferState.confirmedTransfers,
                activeTransferId: widget.transferState.activeTransfer?.id,
                isLoading: widget.transferState.isLoadingLists,
                onSelect: widget.onSelectConfirmedTransfer,
              ),
          },
        ),
      ],
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({
    required this.state,
    required this.searchController,
    required this.onSearchChanged,
    required this.onRefreshProducts,
    required this.onGoToPage,
    required this.onSelectProduct,
  });

  final ProductListState state;
  final TextEditingController searchController;
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
            hintText: 'Pesquisar produto por nome ou código...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              onPressed: state.isLoading ? null : onRefreshProducts,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualizar produtos',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(t.radiusMd),
              borderSide: BorderSide(color: t.border),
            ),
            filled: true,
            fillColor: t.bgPrimary.withValues(alpha: 0.5),
          ),
        ),
        if (state.isLoading)
          Padding(
            padding: EdgeInsets.only(top: s.sm),
            child: const LinearProgressIndicator(),
          ),
        if (state.errorMessage != null) ...[
          SizedBox(height: s.sm),
          Text(
            state.errorMessage!,
            style: TextStyle(color: t.posDanger, fontWeight: FontWeight.w700),
          ),
        ],
        SizedBox(height: s.md),
        Expanded(
          child: state.items.isEmpty
              ? const _EmptyPane(
                  icon: Icons.inventory_2_outlined,
                  title: 'Nenhum produto encontrado',
                  subtitle: 'Ajuste a pesquisa ou actualize o catálogo.',
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) =>
                            Divider(color: t.border.withValues(alpha: 0.25)),
                        itemBuilder: (context, index) {
                          final product = state.items[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  t.brandBlue.withValues(alpha: 0.12),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: t.brandBlue,
                              ),
                            ),
                            title: Text(
                              product.nome,
                              style: TextStyle(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'Stock: ${_formatQuantity(product.estoqueAtual)}'
                              '${product.lote != null ? ' • Lote: ${product.lote}' : ''}',
                              style: TextStyle(color: t.textMuted),
                            ),
                            trailing: const Icon(Icons.add_circle_outline_rounded),
                            onTap: () => onSelectProduct(product),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: s.sm),
                    _PaginationFooter(
                      page: state.page,
                      hasMore: state.hasMore,
                      onPrevious: state.page > 1
                          ? () => onGoToPage(state.page - 1)
                          : null,
                      onNext: state.hasMore
                          ? () => onGoToPage(state.page + 1)
                          : null,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TransferListTab extends StatelessWidget {
  const _TransferListTab({
    required this.title,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.transfers,
    required this.activeTransferId,
    required this.isLoading,
    required this.onSelect,
  });

  final String title;
  final String emptyTitle;
  final String emptySubtitle;
  final List<TransferenciaResumo> transfers;
  final String? activeTransferId;
  final bool isLoading;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    if (isLoading && transfers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transfers.isEmpty) {
      return _EmptyPane(
        icon: Icons.swap_horiz_rounded,
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
            itemCount: transfers.length,
            separatorBuilder: (_, _) =>
                Divider(color: t.border.withValues(alpha: 0.25)),
            itemBuilder: (context, index) {
              final item = transfers[index];
              final isActive = item.id == activeTransferId;
              return ListTile(
                tileColor: isActive
                    ? t.brandBlue.withValues(alpha: 0.08)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: CircleAvatar(
                  backgroundColor: item.status == TransferenciaStatus.confirmada
                      ? t.brandGreen.withValues(alpha: 0.14)
                      : t.brandBlue.withValues(alpha: 0.14),
                  child: Icon(
                    item.status == TransferenciaStatus.confirmada
                        ? Icons.check_circle_outline
                        : Icons.description_outlined,
                    color: item.status == TransferenciaStatus.confirmada
                        ? t.brandGreen
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
                  '${item.origem} -> ${item.destino}\n'
                  '${item.status.label} • ${_formatQuantity(item.quantidadeTotal)} itens',
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
    required this.onConfirm,
    required this.onCancel,
    required this.onRemoveItem,
  });

  final TransferenciaState state;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onCancel;
  final ValueChanged<String> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final transfer = state.activeTransfer;

    if (state.isLoadingActiveTransfer && transfer == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transfer == null) {
      return const _EmptyPane(
        icon: Icons.swap_horiz_rounded,
        title: 'Nenhuma transferência seleccionada',
        subtitle: 'Seleccione um rascunho ou uma transferência confirmada.',
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
                      transfer.numeroDocumento,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: s.xs),
                    Text(
                      '${transfer.origem} -> ${transfer.destino}',
                      style: TextStyle(color: t.textMuted),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: transfer.status),
            ],
          ),
          SizedBox(height: s.md),
          Wrap(
            spacing: s.md,
            runSpacing: s.md,
            children: [
              _InfoCard(
                label: 'Tipo',
                value: transfer.tipo.label,
              ),
              _InfoCard(
                label: 'Itens',
                value: transfer.totalItens.toString(),
              ),
              _InfoCard(
                label: 'Quantidade',
                value: _formatQuantity(transfer.quantidadeTotal),
              ),
              _InfoCard(
                label: 'Criada em',
                value: _formatDate(transfer.createdAt),
              ),
            ],
          ),
          if ((transfer.observacao ?? '').trim().isNotEmpty) ...[
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
              transfer.observacao!,
              style: TextStyle(color: t.textMuted),
            ),
          ],
          if (transfer.user != null) ...[
            SizedBox(height: s.md),
            Text(
              'Criada por ${transfer.user!.nome}',
              style: TextStyle(color: t.textMuted),
            ),
          ],
          SizedBox(height: s.lg),
          Text(
            'Itens da transferência',
            style: TextStyle(
              color: t.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          SizedBox(height: s.sm),
          Expanded(
            child: transfer.itens.isEmpty
                ? const _EmptyPane(
                    icon: Icons.playlist_add_outlined,
                    title: 'Sem itens',
                    subtitle:
                        'Seleccione produtos no painel esquerdo para adicionar itens.',
                  )
                : ListView.separated(
                    itemCount: transfer.itens.length,
                    separatorBuilder: (_, _) => Divider(
                      color: t.border.withValues(alpha: 0.25),
                    ),
                    itemBuilder: (context, index) {
                      final item = transfer.itens[index];
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
                          'Quantidade: ${_formatQuantity(item.quantidade)}'
                          '${item.lote != null ? ' • Lote: ${item.lote!.numeroLote}' : ''}'
                          '${item.lote?.dataValidade != null ? ' • Validade: ${_formatDate(item.lote!.dataValidade!)}' : ''}',
                          style: TextStyle(color: t.textMuted),
                        ),
                        trailing: state.canEditActiveTransfer
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
          if (state.canEditActiveTransfer) ...[
            SizedBox(height: s.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.canCancelActiveTransfer &&
                            !state.isCancellingTransfer &&
                            !state.isConfirmingTransfer
                        ? onCancel
                        : null,
                    icon: state.isCancellingTransfer
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close_rounded),
                    label: const Text('Cancelar'),
                  ),
                ),
                SizedBox(width: s.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.canConfirmActiveTransfer &&
                            !state.isConfirmingTransfer &&
                            !state.isCancellingTransfer
                        ? onConfirm
                        : null,
                    icon: state.isConfirmingTransfer
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Confirmar Transferência'),
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

  final TransferenciaStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final color = switch (status) {
      TransferenciaStatus.confirmada => t.brandGreen,
      TransferenciaStatus.cancelada => t.posDanger,
      TransferenciaStatus.rascunho => t.brandBlue,
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

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.page,
    required this.hasMore,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final bool hasMore;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
          label: const Text('Anterior'),
        ),
        const Spacer(),
        Text(
          'Página $page',
          style: TextStyle(color: t.textMuted, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: hasMore ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
          label: const Text('Próxima'),
        ),
      ],
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

class NovaTransferenciaDialogResult {
  const NovaTransferenciaDialogResult({
    required this.numeroDocumento,
    required this.origem,
    required this.destino,
    required this.tipo,
    this.observacao,
  });

  final String numeroDocumento;
  final String origem;
  final String destino;
  final TransferenciaTipo tipo;
  final String? observacao;
}

class _NovaTransferenciaDialog extends StatefulWidget {
  const _NovaTransferenciaDialog();

  @override
  State<_NovaTransferenciaDialog> createState() => _NovaTransferenciaDialogState();
}

class _NovaTransferenciaDialogState extends State<_NovaTransferenciaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _origemController = TextEditingController();
  final _destinoController = TextEditingController();
  final _observacaoController = TextEditingController();
  TransferenciaTipo _tipo = TransferenciaTipo.saida;

  @override
  void dispose() {
    _numeroController.dispose();
    _origemController.dispose();
    _destinoController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      NovaTransferenciaDialogResult(
        numeroDocumento: _numeroController.text.trim(),
        origem: _origemController.text.trim(),
        destino: _destinoController.text.trim(),
        tipo: _tipo,
        observacao: _observacaoController.text.trim().isEmpty
            ? null
            : _observacaoController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova transferência'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tipo de transferência',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TransferenciaTipo>(
                segments: const [
                  ButtonSegment(
                    value: TransferenciaTipo.saida,
                    label: Text('Saída'),
                    icon: Icon(Icons.arrow_upward_rounded),
                  ),
                  ButtonSegment(
                    value: TransferenciaTipo.entrada,
                    label: Text('Entrada'),
                    icon: Icon(Icons.arrow_downward_rounded),
                  ),
                ],
                selected: {_tipo},
                onSelectionChanged: (selection) {
                  setState(() => _tipo = selection.first);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numeroController,
                decoration: const InputDecoration(
                  labelText: 'Número do documento',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o número do documento'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _origemController,
                decoration: const InputDecoration(labelText: 'Origem'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe a origem'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _destinoController,
                decoration: const InputDecoration(labelText: 'Destino'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o destino'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacaoController,
                decoration: const InputDecoration(labelText: 'Observação'),
                minLines: 2,
                maxLines: 4,
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
        FilledButton(
          onPressed: _submit,
          child: const Text('Criar'),
        ),
      ],
    );
  }
}

class _TransferenciaLoteDialog extends ConsumerStatefulWidget {
  const _TransferenciaLoteDialog({
    required this.product,
  });

  final Product product;

  @override
  ConsumerState<_TransferenciaLoteDialog> createState() =>
      _TransferenciaLoteDialogState();
}

class _TransferenciaLoteDialogState extends ConsumerState<_TransferenciaLoteDialog> {
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
          .read(transferenciaRepositoryProvider)
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
      TransferenciaItemDraft(
        produtoId: widget.product.id,
        produtoNome: widget.product.nome,
        quantidade: double.parse(_quantidadeController.text.replaceAll(',', '.')),
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
                : _lotes.isEmpty
                    ? const Text('Nenhum lote disponível para este produto.')
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                      'Validade: ${_formatDate(lote.dataValidade)} • '
                                      'Stock: ${_formatQuantity(lote.quantidadeAtual)}',
                                    ),
                                    onTap: () =>
                                        setState(() => _selectedLote = lote),
                                  );
                                },
                              ),
                            ),
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
                                if (_selectedLote != null &&
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
        FilledButton(
          onPressed: _lotes.isEmpty || _selectedLote == null ? null : _submit,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
