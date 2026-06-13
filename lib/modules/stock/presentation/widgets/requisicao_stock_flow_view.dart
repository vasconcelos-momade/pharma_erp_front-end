import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/feedback/pharma_snackbar.dart';
import '../../../pharmacy/products/domain/entities/product.dart';
import '../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../domain/entities/requisicao.dart';
import '../../data/repositories/requisicao_repository_impl.dart';
import '../providers/requisicao_provider.dart';
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

  final displayMatch = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(normalized);
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
    digitsBeforeCursor =
        RegExp(r'\d').allMatches(newValue.text.substring(0, cursor)).length;
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
    final dataValidade =
        stockFlowParseDateInput(_dataValidadeController.text.trim());
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
        final fornecedorId =
            ref.read(requisicaoProvider).activeRequisicao?.fornecedorId;
        if (fornecedorId == null || fornecedorId.trim().isEmpty) {
          setState(() {
            _error =
                'Associe um fornecedor à requisição antes de registar um novo lote.';
          });
          return;
        }

        final created = await ref.read(requisicaoProvider.notifier).criarLote(
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

    return AlertDialog(
      title: Text('Adicionar ${widget.product.nome}'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loadingLotes)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(color: t.posDanger),
                  ),
                  SizedBox(height: s.sm),
                ],
                TextFormField(
                  controller: _loteController,
                  decoration: const InputDecoration(
                    labelText: 'Lote',
                    hintText: 'Ex.: LOTE-2026-001',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Informe o número do lote'
                          : null,
                ),
                SizedBox(height: s.md),
                TextFormField(
                  controller: _dataValidadeController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    _StockFlowDateTextInputFormatter(),
                  ],
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
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Adicionar'),
        ),
      ],
    );
  }
}
