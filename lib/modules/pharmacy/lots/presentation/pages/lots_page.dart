import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/async_value_extensions.dart';
import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/responsive/responsive_builder.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../providers/lots_provider.dart';
import '../widgets/open_lote_details.dart';
import '../widgets/lot_actions_helper.dart';
import '../../../presentation/widgets/pharmacy_report_exports.dart';

class LotsPage extends ConsumerStatefulWidget {
  const LotsPage({super.key});

  @override
  ConsumerState<LotsPage> createState() => _LotsPageState();
}

class _LotsPageState extends ConsumerState<LotsPage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _accumulatedItems = [];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Color _validadeColor(BuildContext context, String? indicador) {
    final t = context.pharmaTokens;
    switch (indicador) {
      case 'EXPIRADO':
        return t.posDanger;
      case '30_DIAS':
        return Colors.orange;
      case '60_DIAS':
        return Colors.amber.shade700;
      default:
        return t.brandGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(lotsViewProvider);
    final controller = ref.read(lotsViewProvider.notifier);
    final current = asyncState.valueOrNull;
    final dash = current?.dashboard;
    final t = context.pharmaTokens;
    final s = context.spacing;
    final reportPath = current?.expirado == true
        ? ReportPaths.pharmacyLotsExpired
        : ReportPaths.pharmacyLotsActive;
    final reportQuery = <String, dynamic>{
      if ((current?.query ?? '').isNotEmpty) 'q': current!.query,
      if (current?.estadoSanitario != null) 'estadoSanitario': current!.estadoSanitario,
      if (current?.disponibilidade != null) 'disponibilidade': current!.disponibilidade,
    };

    if (current != null && _search.text != current.query) {
      _search.value = TextEditingValue(
        text: current.query,
        selection: TextSelection.collapsed(offset: current.query.length),
      );
    }

    ref.listen(lotsViewProvider, (prev, next) {
      final previous = prev?.valueOrNull;
      final upcoming = next.valueOrNull;
      if (upcoming == null) return;

      if (previous?.page != upcoming.page ||
          previous?.query != upcoming.query ||
          previous?.estadoSanitario != upcoming.estadoSanitario ||
          previous?.disponibilidade != upcoming.disponibilidade ||
          previous?.expirado != upcoming.expirado ||
          previous?.pageSize != upcoming.pageSize) {
        if (upcoming.page == 1) {
          _accumulatedItems = List.of(upcoming.items);
        } else {
          final newItems = upcoming.items
              .where(
                (e) => !_accumulatedItems.any(
                  (a) => a['id']?.toString() == e['id']?.toString(),
                ),
              )
              .toList();
          _accumulatedItems.addAll(newItems);
        }
      } else if (previous?.items != upcoming.items && upcoming.page == 1) {
        _accumulatedItems = List.of(upcoming.items);
      }
    });

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return EnterpriseModuleHub(
          mobileKpisHorizontalScroll: true,
          kpis: dash == null
              ? null
              : [
                  EnterpriseStatCard(
                    title: 'Total de lotes',
                    value: '${dash['totalLotes'] ?? 0}',
                    icon: Icons.inventory_2_outlined,
                  ),
                  EnterpriseStatCard(
                    title: 'Disponíveis',
                    value: '${dash['lotesDisponiveis'] ?? 0}',
                    icon: Icons.check_circle_outline,
                  ),
                  EnterpriseStatCard(
                    title: 'Sanitários',
                    value: '${dash['lotesSanitarios'] ?? 0}',
                    icon: Icons.health_and_safety_outlined,
                  ),
                  EnterpriseStatCard(
                    title: 'Alertas',
                    value: '${dash['alertasOperacionais'] ?? 0}',
                    icon: Icons.notifications_active_outlined,
                  ),
                ],
          actions: [
            ...pharmacyReportActions(
              ref: ref,
              enabled: !asyncState.isLoading,
              path: reportPath,
              queryParameters: reportQuery,
            ),
            IconButton(
              onPressed: () => controller.refresh(force: true),
              icon: const Icon(Icons.refresh),
            ),
          ],
          filters: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 260,
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Produto ou nº lote...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: controller.setSearch,
                ),
              ),
              DropdownMenu<String?>(
                label: const Text('Estado sanitário'),
                initialSelection: current?.estadoSanitario,
                onSelected: controller.setEstadoSanitario,
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: null, label: 'Todos'),
                  DropdownMenuEntry(value: 'VALIDO', label: 'Válido'),
                  DropdownMenuEntry(value: 'EXPIRADO', label: 'Expirado'),
                  DropdownMenuEntry(value: 'QUARENTENA', label: 'Quarentena'),
                  DropdownMenuEntry(value: 'RECALL', label: 'Recall'),
                ],
              ),
              DropdownMenu<String?>(
                label: const Text('Disponibilidade'),
                initialSelection: current?.disponibilidade,
                onSelected: controller.setDisponibilidade,
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: null, label: 'Todas'),
                  DropdownMenuEntry(value: 'DISPONIVEL', label: 'Disponível'),
                  DropdownMenuEntry(value: 'RESERVADO', label: 'Reservado'),
                  DropdownMenuEntry(value: 'BLOQUEADO', label: 'Bloqueado'),
                  DropdownMenuEntry(value: 'INDISPONIVEL', label: 'Indisponível'),
                ],
              ),
              FilterChip(
                label: const Text('Expirados'),
                selected: current?.expirado == true,
                onSelected: (v) => controller.setExpirado(v ? true : null),
              ),
            ],
          ),
          child: Column(
            children: [
              if (asyncState.isLoading) const LinearProgressIndicator(),
              if (asyncState.hasError)
                Padding(
                  padding: EdgeInsets.only(bottom: s.sm),
                  child: Text(
                    asyncState.error.toString(),
                    style: TextStyle(color: t.posDanger),
                  ),
                ),
              Expanded(
                child: isMobile
                    ? _LotsMobileList(
                        items: _accumulatedItems,
                        hasMore: current?.hasMore ?? false,
                        isLoading: asyncState.isLoading,
                        actionLoteId: current?.actionLoteId,
                        validadeColor: (indicador) =>
                            _validadeColor(context, indicador),
                        onLoadMore: () => controller.goToPage((current?.page ?? 1) + 1),
                        onOpenDetails: _openLoteDetails,
                        onAction: _handleAction,
                      )
                    : (current?.items.isEmpty ?? true) && !asyncState.isLoading
                        ? const Center(child: Text('Nenhum lote encontrado'))
                        : EnterpriseDataTable(
                            columns: const [
                              DataColumn(label: Text('PRODUTO')),
                              DataColumn(label: Text('Nº LOTE')),
                              DataColumn(label: Text('VALIDADE')),
                              DataColumn(label: Text('STOCK')),
                              DataColumn(label: Text('P. COMPRA')),
                              DataColumn(label: Text('P. VENDA')),
                              DataColumn(label: Text('ESTADO')),
                              DataColumn(label: Text('AÇÕES')),
                            ],
                            rowCount: current?.items.length ?? 0,
                            rowBuilder: (context, index) {
                              final item = current!.items[index];
                              final loteId = item['id']?.toString() ?? '';
                              final color = _validadeColor(
                                context,
                                item['indicadorValidade'] as String?,
                              );
                              final isBusy = current.actionLoteId == loteId;
                              return DataRow(
                                onSelectChanged: (_) => _openLoteDetails(loteId),
                                cells: [
                                  DataCell(Text(item['produtoNome']?.toString() ?? '—')),
                                  DataCell(Text(item['numeroLote']?.toString() ?? '—')),
                                  DataCell(
                                    Text(
                                      item['dataValidade']?.toString().substring(0, 10) ?? '—',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(item['quantidadeDisponivel']?.toString() ?? '0')),
                                  DataCell(Text(item['precoCompra']?.toString() ?? '—')),
                                  DataCell(Text(item['precoVenda']?.toString() ?? '—')),
                                  DataCell(Text(item['estadoSanitario']?.toString() ?? '—')),
                                  DataCell(
                                    isBusy
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : PopupMenuButton<String>(
                                            tooltip: 'Acções do lote',
                                            onSelected: (action) => _handleAction(action, item),
                                            itemBuilder: (context) => [
                                              if (LotActionsHelper.canMoveToQuarentena(item))
                                                const PopupMenuItem(
                                                  value: 'quarentena',
                                                  child: Text('Mover para Quarentena'),
                                                ),
                                              if (LotActionsHelper.canRevertQuarentena(item))
                                                const PopupMenuItem(
                                                  value: 'reverter',
                                                  child: Text('Reverter Quarentena'),
                                                ),
                                              const PopupMenuItem(
                                                value: 'historico',
                                                child: Text('Visualizar histórico'),
                                              ),
                                            ],
                                            icon: const Icon(Icons.more_vert),
                                          ),
                                  ),
                                ],
                              );
                            },
                          ),
              ),
              if (!isMobile)
                MovimentacoesPagination(
                  page: current?.page ?? 1,
                  pageSize: current?.pageSize ?? 20,
                  hasMore: current?.hasMore ?? false,
                  isBusy: asyncState.isLoading,
                  onPrev: (current?.page ?? 1) > 1
                      ? () => controller.goToPage((current?.page ?? 1) - 1)
                      : null,
                  onNext: current?.hasMore == true
                      ? () => controller.goToPage((current?.page ?? 1) + 1)
                      : null,
                  onPageSizeChanged: controller.setPageSize,
                ),
              if (current?.totalCount != null)
                Text(
                  'Total: ${current!.totalCount} lote(s)',
                  style: TextStyle(color: t.textMuted, fontSize: 12),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAction(String action, Map<String, dynamic> lote) async {
    final loteId = lote['id']?.toString() ?? '';
    if (loteId.isEmpty) return;

    switch (action) {
      case 'quarentena':
        await LotActionsHelper.moveToQuarentena(context, ref, lote);
      case 'reverter':
        await LotActionsHelper.revertQuarentena(context, ref, lote);
      case 'historico':
        await LotActionsHelper.showHistory(
          context,
          ref,
          loteId,
          numeroLote: lote['numeroLote']?.toString(),
        );
    }
  }

  Future<void> _openLoteDetails(String loteId) => openLoteDetails(context, loteId);
}

class _LotsMobileList extends StatefulWidget {
  const _LotsMobileList({
    required this.items,
    required this.hasMore,
    required this.isLoading,
    required this.actionLoteId,
    required this.validadeColor,
    required this.onLoadMore,
    required this.onOpenDetails,
    required this.onAction,
  });

  final List<Map<String, dynamic>> items;
  final bool hasMore;
  final bool isLoading;
  final String? actionLoteId;
  final Color Function(String? indicador) validadeColor;
  final VoidCallback onLoadMore;
  final void Function(String loteId) onOpenDetails;
  final Future<void> Function(String action, Map<String, dynamic> lote) onAction;

  @override
  State<_LotsMobileList> createState() => _LotsMobileListState();
}

class _LotsMobileListState extends State<_LotsMobileList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    if (widget.items.isEmpty && !widget.isLoading) {
      return const Center(child: Text('Nenhum lote encontrado'));
    }

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.all(s.md),
      itemCount: widget.items.length + 1,
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemBuilder: (context, index) {
        if (index == widget.items.length) {
          if (widget.isLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          if (!widget.hasMore && widget.items.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Fim da lista',
                  style: TextStyle(color: t.textMuted, fontSize: 12),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final lote = widget.items[index];
        return _LoteMobileCard(
          lote: lote,
          isBusy: widget.actionLoteId == lote['id']?.toString(),
          validadeColor: widget.validadeColor,
          onTap: () => widget.onOpenDetails(lote['id']?.toString() ?? ''),
          onAction: (action) => widget.onAction(action, lote),
        );
      },
    );
  }
}

class _LoteMobileCard extends StatelessWidget {
  const _LoteMobileCard({
    required this.lote,
    required this.isBusy,
    required this.validadeColor,
    required this.onTap,
    required this.onAction,
  });

  final Map<String, dynamic> lote;
  final bool isBusy;
  final Color Function(String? indicador) validadeColor;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);
    final color = validadeColor(lote['indicadorValidade'] as String?);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(t.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: t.iconSm,
                    color: t.textPrimary,
                  ),
                  SizedBox(width: s.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lote['produtoNome']?.toString() ?? '—',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: s.xxs),
                        Text(
                          'Lote: ${lote['numeroLote']?.toString() ?? '—'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: t.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: s.xs),
                  _LoteStatusChip(
                    label: lote['estadoSanitario']?.toString() ?? '—',
                  ),
                  if (isBusy)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: t.minTouchTarget * 0.6,
                        minHeight: t.minTouchTarget * 0.6,
                      ),
                      icon: Icon(Icons.more_vert, size: t.iconSm, color: t.textMuted),
                      onSelected: onAction,
                      itemBuilder: (context) => [
                        if (LotActionsHelper.canMoveToQuarentena(lote))
                          const PopupMenuItem(
                            value: 'quarentena',
                            child: Text('Mover para Quarentena'),
                          ),
                        if (LotActionsHelper.canRevertQuarentena(lote))
                          const PopupMenuItem(
                            value: 'reverter',
                            child: Text('Reverter Quarentena'),
                          ),
                        const PopupMenuItem(
                          value: 'historico',
                          child: Text('Visualizar histórico'),
                        ),
                      ],
                    ),
                ],
              ),
              SizedBox(height: s.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Validade: ${_formatDate(lote['dataValidade'])}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: s.sm),
                  Text(
                    'Stock: ${lote['quantidadeDisponivel']?.toString() ?? '0'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: t.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: s.xxs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Compra: ${lote['precoCompra']?.toString() ?? '—'}',
                      style: theme.textTheme.bodySmall?.copyWith(color: t.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: s.sm),
                  Expanded(
                    child: Text(
                      'Venda: ${lote['precoVenda']?.toString() ?? '—'}',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(color: t.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return '—';
    return text.length >= 10 ? text.substring(0, 10) : text;
  }
}

class _LoteStatusChip extends StatelessWidget {
  const _LoteStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final normalized = label.toUpperCase();
    final color = switch (normalized) {
      'VALIDO' => t.brandGreen,
      'EXPIRADO' => t.posDanger,
      'QUARENTENA' => Colors.orange,
      'RECALL' => Colors.deepOrange,
      _ => t.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
