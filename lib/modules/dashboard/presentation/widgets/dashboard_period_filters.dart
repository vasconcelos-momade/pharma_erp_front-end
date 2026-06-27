import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../providers/dashboard_providers.dart';
import '../../domain/dashboard_query.dart';
import 'dashboard_widgets.dart';

typedef DashboardQueryChanged = void Function(DashboardQuery query);

class DashboardPeriodFilters extends ConsumerStatefulWidget {
  const DashboardPeriodFilters({
    super.key,
    required this.query,
    required this.onChanged,
    this.extraFilters,
    this.showSearch = true,
    this.showCategoryFilter = false,
    this.showProductFilter = false,
    this.statusOptions = const [],
    this.paymentMethodOptions = const [],
    this.movementTypeOptions = const [],
  });

  final DashboardQuery query;
  final DashboardQueryChanged onChanged;
  final List<Widget>? extraFilters;
  final bool showSearch;
  final bool showCategoryFilter;
  final bool showProductFilter;
  final List<DashboardFilterOption> statusOptions;
  final List<DashboardFilterOption> paymentMethodOptions;
  final List<DashboardFilterOption> movementTypeOptions;

  @override
  ConsumerState<DashboardPeriodFilters> createState() => _DashboardPeriodFiltersState();
}

class _DashboardPeriodFiltersState extends ConsumerState<DashboardPeriodFilters> {
  late final TextEditingController _searchController;

  DashboardQuery get query => widget.query;
  DashboardQueryChanged get onChanged => widget.onChanged;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query.search);
  }

  @override
  void didUpdateWidget(covariant DashboardPeriodFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query.search != widget.query.search &&
        _searchController.text != widget.query.search) {
      _searchController.text = widget.query.search;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final categoriesAsync = widget.showCategoryFilter
        ? ref.watch(dashboardFilterCategoriesProvider)
        : const AsyncValue.data([]);
    final productsAsync = widget.showProductFilter
        ? ref.watch(dashboardFilterProductsProvider)
        : const AsyncValue.data([]);

    final presets = <(DashboardPeriodPreset, String)>[
      (DashboardPeriodPreset.today, 'Hoje'),
      (DashboardPeriodPreset.yesterday, 'Ontem'),
      (DashboardPeriodPreset.last7days, '7 dias'),
      (DashboardPeriodPreset.last30days, '30 dias'),
      (DashboardPeriodPreset.thisMonth, 'Este mês'),
      (DashboardPeriodPreset.lastMonth, 'Mês anterior'),
      (DashboardPeriodPreset.thisYear, 'Este ano'),
    ];

    final hasCustomRange =
        widget.query.period == DashboardPeriodPreset.custom &&
        widget.query.from != null &&
        widget.query.to != null;

    final categoryOptions = categoriesAsync.maybeWhen(
      data: (items) => items
          .map((item) => DashboardFilterOption(value: item.id, label: item.nome))
          .toList(growable: false),
      orElse: () => const <DashboardFilterOption>[],
    );
    final productOptions = productsAsync.maybeWhen(
      data: (items) => items
          .map((item) => DashboardFilterOption(value: item.id, label: item.nome))
          .toList(growable: false),
      orElse: () => const <DashboardFilterOption>[],
    );

    return Container(
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: s.sm,
            runSpacing: s.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.showSearch)
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: t.card,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(t.radiusXl),
                      ),
                    ),
                    onChanged: (value) => onChanged(query.copyWith(search: value)),
                  ),
                ),
              if (widget.showCategoryFilter)
                DashboardFilterSelect(
                  label: 'Categoria',
                  options: categoryOptions,
                  value: query.categoriaId,
                  onChanged: (value) => onChanged(
                    query.copyWith(
                      categoriaId: value,
                      clearCategoriaId: value == null,
                    ),
                  ),
                ),
              if (widget.showProductFilter)
                DashboardFilterSelect(
                  label: 'Produto',
                  options: productOptions,
                  value: query.produtoId,
                  onChanged: (value) => onChanged(
                    query.copyWith(
                      produtoId: value,
                      clearProdutoId: value == null,
                    ),
                  ),
                ),
              if (widget.statusOptions.isNotEmpty)
                DashboardFilterSelect(
                  label: 'Estado',
                  options: widget.statusOptions,
                  value: query.estado,
                  onChanged: (value) => onChanged(
                    query.copyWith(
                      estado: value,
                      clearEstado: value == null,
                    ),
                  ),
                ),
              if (widget.paymentMethodOptions.isNotEmpty)
                DashboardFilterSelect(
                  label: 'Pagamento',
                  options: widget.paymentMethodOptions,
                  value: query.metodoPagamento,
                  onChanged: (value) => onChanged(
                    query.copyWith(
                      metodoPagamento: value,
                      clearMetodoPagamento: value == null,
                    ),
                  ),
                ),
              if (widget.movementTypeOptions.isNotEmpty)
                DashboardFilterSelect(
                  label: 'Movimentação',
                  options: widget.movementTypeOptions,
                  value: query.tipoMovimentacao,
                  onChanged: (value) => onChanged(
                    query.copyWith(
                      tipoMovimentacao: value,
                      clearTipoMovimentacao: value == null,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: s.sm),
          Wrap(
            spacing: s.sm,
            runSpacing: s.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (preset, label) in presets)
                FilterChip(
                  label: Text(label),
                  selected: query.period == preset,
                  onSelected: (_) => onChanged(
                    query.copyWith(
                      period: preset,
                      clearFrom: true,
                      clearTo: true,
                      days: preset == DashboardPeriodPreset.last7days
                          ? 7
                          : preset == DashboardPeriodPreset.last30days
                              ? 30
                              : query.days,
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => _pickCustomRange(context),
                icon: const Icon(Icons.date_range_rounded),
                label: Text(
                  hasCustomRange
                      ? _formatRange(query.from!, query.to!)
                      : 'Intervalo personalizado',
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      hasCustomRange ? t.brandBlue.withValues(alpha: 0.08) : null,
                ),
              ),
              if (query.hasActiveFilters)
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    onChanged(const DashboardQuery());
                  },
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Limpar'),
                ),
              if (widget.extraFilters != null) ...?widget.extraFilters,
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final initial = query.from != null && query.to != null
        ? DateTimeRange(start: query.from!, end: query.to!)
        : DateTimeRange(
            start: DateTime(now.year, now.month, now.day)
                .subtract(const Duration(days: 29)),
            end: DateTime(now.year, now.month, now.day),
          );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      helpText: 'Seleccionar intervalo',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
      fieldStartHintText: 'Data inicial',
      fieldEndHintText: 'Data final',
    );

    if (picked == null) return;
    onChanged(
      query.copyWith(
        period: DashboardPeriodPreset.custom,
        from: picked.start,
        to: picked.end,
      ),
    );
  }

  String _formatRange(DateTime from, DateTime to) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return '${fmt(from)} – ${fmt(to)}';
  }
}
