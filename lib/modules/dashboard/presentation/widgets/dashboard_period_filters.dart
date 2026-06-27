import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/dashboard_query.dart';

typedef DashboardQueryChanged = void Function(DashboardQuery query);

class DashboardPeriodFilters extends StatelessWidget {
  const DashboardPeriodFilters({
    super.key,
    required this.query,
    required this.onChanged,
    this.extraFilters,
    this.showSearch = true,
  });

  final DashboardQuery query;
  final DashboardQueryChanged onChanged;
  final List<Widget>? extraFilters;
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

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
        query.period == DashboardPeriodPreset.custom &&
        query.from != null &&
        query.to != null;

    return Wrap(
      spacing: s.sm,
      runSpacing: s.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showSearch)
          SizedBox(
            width: 280,
            child: TextField(
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
                : 'Intervalo',
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor:
                hasCustomRange ? t.brandBlue.withValues(alpha: 0.08) : null,
          ),
        ),
        if (query.hasActiveFilters)
          TextButton.icon(
            onPressed: () => onChanged(
              const DashboardQuery(),
            ),
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Limpar'),
          ),
        if (extraFilters != null) ...?extraFilters,
      ],
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
