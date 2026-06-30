import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/pharma_surface.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../domain/dashboard_query.dart';
import 'dashboard_state_widgets.dart';

class DashboardPagedTableResult {
  const DashboardPagedTableResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.totalCount,
    this.totalPages,
    this.hasPrevious = false,
  });

  final List<Map<String, dynamic>> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;
  final int? totalPages;
  final bool hasPrevious;

  factory DashboardPagedTableResult.fromMap(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    final page = asInt(json['page'], fallback: 1);
    final pageSize = asInt(json['pageSize'], fallback: 10);
    final totalCount =
        json['totalCount'] == null ? null : asInt(json['totalCount']);
    final totalPages = json['totalPages'] == null
        ? (totalCount == null ? null : (totalCount / pageSize).ceil().clamp(1, 9999))
        : asInt(json['totalPages'], fallback: 1);

    return DashboardPagedTableResult(
      items: dashList(json['items']),
      page: page,
      pageSize: pageSize,
      hasMore: json['hasMore'] == true,
      totalCount: totalCount,
      totalPages: totalPages,
      hasPrevious: json['hasPrevious'] == true || page > 1,
    );
  }
}

class DashboardFilterOption {
  const DashboardFilterOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class DashboardTableColumn {
  const DashboardTableColumn({
    required this.label,
    this.sortKey,
  });

  final String label;
  final String? sortKey;
}

class DashboardFilterSelect extends StatelessWidget {
  const DashboardFilterSelect({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.width,
  });

  final String label;
  final List<DashboardFilterOption> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return PharmaInstantDropdown<String>(
      label: label,
      width: width,
      value: options.any((option) => option.value == value) ? value : null,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Todos'),
        ),
        ...options.map(
          (option) => DropdownMenuItem<String>(
            value: option.value,
            child: Text(
              option.label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

String dashKpi(Map<String, dynamic>? data, String key, {String suffix = ''}) {
  final value = data?[key];
  if (value == null) return '—';
  if (value is num) {
    final rounded = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    return '$rounded$suffix';
  }
  return '$value$suffix';
}

List<Map<String, dynamic>> dashList(dynamic value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList();
  }
  return const [];
}

Map<String, dynamic>? dashMap(dynamic value) {
  return value is Map<String, dynamic> ? value : null;
}

String dashLabel(dynamic value, {int max = 8}) {
  final label = value?.toString() ?? '';
  if (label.isEmpty) return '—';
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(label)) {
    return '${label.substring(8, 10)}/${label.substring(5, 7)}';
  }
  if (RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(label)) {
    return '${label.substring(8, 10)}/${label.substring(5, 7)}';
  }
  if (RegExp(r'^\d{4}-\d{2}$').hasMatch(label)) {
    return '${label.substring(5, 7)}/${label.substring(2, 4)}';
  }
  if (label.length <= max) return label;
  return label.substring(0, max);
}

List<DashboardFilterOption> dashboardUniqueOptions(
  Iterable<dynamic> values, {
  Map<String, String>? labels,
}) {
  final seen = <String>{};
  final items = <DashboardFilterOption>[];
  for (final value in values) {
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty || !seen.add(normalized)) {
      continue;
    }
    items.add(
      DashboardFilterOption(
        value: normalized,
        label: labels?[normalized] ?? normalized,
      ),
    );
  }
  items.sort((a, b) => a.label.compareTo(b.label));
  return items;
}

/// Altura mínima e máxima recomendadas para a área de gráfico dentro do card.
const double kDashboardChartMinHeight = 240.0;
const double kDashboardChartMaxHeight = 420.0;

Widget _dashboardChartEmptyState(
  BuildContext context, {
  String message = 'Sem dados no período',
}) {
  final t = context.pharmaTokens;
  return LayoutBuilder(
    builder: (context, constraints) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: t.textMuted),
          ),
        ),
      );
    },
  );
}

Widget _dashboardScrollableChart({
  required double minWidth,
  required Widget child,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
          ? constraints.maxWidth
          : minWidth;
      final maxH = constraints.maxHeight.isFinite && constraints.maxHeight > 0
          ? constraints.maxHeight
          : null;
      final contentWidth = math.max(maxW, minWidth);
      final needsHorizontalScroll = contentWidth > maxW + 0.5;

      final chart = SizedBox(
        width: needsHorizontalScroll ? contentWidth : maxW,
        height: maxH,
        child: child,
      );

      if (needsHorizontalScroll) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: chart,
        );
      }
      return chart;
    },
  );
}

Widget _dashboardChartLegend({
  required List<(String label, Color color)> items,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final legend = Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          for (final (label, color) in items)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : double.infinity,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: legend,
        ),
      );
    },
  );
}

double _dashboardChartMinWidthForCount(int count, {double perItem = 52}) {
  if (count <= 0) return 280;
  return (count * perItem).clamp(280, 1600).toDouble();
}

Widget _dashboardAxisLabel({
  required TitleMeta meta,
  required String label,
  double angle = 0,
}) {
  return SideTitleWidget(
    meta: meta,
    space: 8,
    angle: angle,
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 10),
    ),
  );
}

Widget dashboardAsyncBody<T>({
  required AsyncValue<T> async,
  required Widget Function(T data) builder,
  VoidCallback? onRetry,
  int loadingKpiCount = 4,
}) {
  return async.when(
    loading: () => DashboardLoadingState(kpiCount: loadingKpiCount),
    error: (error, _) => DashboardErrorState(
      message: '$error',
      onRetry: onRetry ?? () {},
    ),
    data: builder,
  );
}

Widget dashboardLineChart({
  required BuildContext context,
  required List<Map<String, dynamic>> points,
  required String valueKey,
  String? labelKey,
  Color? color,
}) {
  final t = context.pharmaTokens;
  if (points.isEmpty) {
    return _dashboardChartEmptyState(context);
  }

  final spots = <FlSpot>[];
  var maxY = 0.0;
  for (var i = 0; i < points.length; i++) {
    final y = (points[i][valueKey] as num?)?.toDouble() ?? 0;
    if (y > maxY) maxY = y;
    spots.add(FlSpot(i.toDouble(), y));
  }
  final chartMax = maxY < 1 ? 1.0 : maxY * 1.15;
  final minWidth = labelKey == null
      ? 280.0
      : _dashboardChartMinWidthForCount(points.length);

  return _dashboardScrollableChart(
    minWidth: minWidth,
    child: ClipRect(
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: chartMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: t.border.withValues(alpha: 0.22), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: labelKey == null
                ? const AxisTitles(sideTitles: SideTitles(showTitles: false))
                : AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return DefaultTextStyle(
                          style: TextStyle(color: t.textMuted),
                          child: _dashboardAxisLabel(
                            meta: meta,
                            label: dashLabel(points[i][labelKey], max: 10),
                          ),
                        );
                      },
                    ),
                  ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color ?? t.brandGreen,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: (color ?? t.brandGreen).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget dashboardChartCard({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  final t = context.pharmaTokens;
  return PharmaSurface(
    padding: t.density.cardPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: t.textMuted,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: t.density.md),
        Expanded(child: child),
      ],
    ),
  );
}

Widget dashboardBarChart({
  required BuildContext context,
  required List<Map<String, dynamic>> points,
  required String valueKey,
  required String labelKey,
  Color? color,
}) {
  final t = context.pharmaTokens;
  if (points.isEmpty) {
    return _dashboardChartEmptyState(context);
  }

  final values = points
      .map((point) => (point[valueKey] as num?)?.toDouble() ?? 0)
      .toList(growable: false);
  final maxY = values.fold<double>(0, (a, b) => a > b ? a : b);
  final chartMax = maxY < 1 ? 1.0 : maxY * 1.2;
  final minWidth = _dashboardChartMinWidthForCount(points.length, perItem: 74);

  return _dashboardScrollableChart(
    minWidth: minWidth,
    child: BarChart(
      BarChartData(
        maxY: chartMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: t.border.withValues(alpha: 0.22), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return DefaultTextStyle(
                  style: TextStyle(color: t.textMuted),
                  child: _dashboardAxisLabel(
                    meta: meta,
                    label: dashLabel(points[i][labelKey], max: 14),
                    angle: -0.5,
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(points.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                width: 18,
                color: color ?? t.brandBlue,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    ),
  );
}

Widget dashboardDualLineChart({
  required BuildContext context,
  required List<Map<String, dynamic>> points,
}) {
  final t = context.pharmaTokens;
  if (points.isEmpty) {
    return _dashboardChartEmptyState(context);
  }

  final receitas = <FlSpot>[];
  final despesas = <FlSpot>[];
  var maxY = 0.0;
  for (var i = 0; i < points.length; i++) {
    final r = (points[i]['receitas'] as num?)?.toDouble() ?? 0;
    final d = (points[i]['despesas'] as num?)?.toDouble() ?? 0;
    maxY = [maxY, r, d].reduce((a, b) => a > b ? a : b);
    receitas.add(FlSpot(i.toDouble(), r));
    despesas.add(FlSpot(i.toDouble(), d));
  }
  final chartMax = maxY < 1 ? 1.0 : maxY * 1.15;
  final minWidth = _dashboardChartMinWidthForCount(points.length);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: _dashboardScrollableChart(
          minWidth: minWidth,
          child: ClipRect(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: chartMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: t.border.withValues(alpha: 0.22),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: receitas,
                    isCurved: true,
                    color: t.brandGreen,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: despesas,
                    isCurved: true,
                    color: t.brandBlue,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      _dashboardChartLegend(
        items: [
          ('Receitas', t.brandGreen),
          ('Despesas', t.brandBlue),
        ],
      ),
    ],
  );
}

Widget dashboardIndexedBarChart({
  required BuildContext context,
  required List<double> values,
  required List<String> labels,
  List<Color>? barColors,
  double barWidth = 22,
}) {
  final t = context.pharmaTokens;
  if (values.isEmpty) {
    return _dashboardChartEmptyState(context);
  }

  final palette = barColors ??
      [
        t.posDanger,
        t.posWarning,
        t.brandBlue,
        t.brandGreen,
        t.textSecondary,
      ];
  final maxY = values.fold<double>(0, (a, b) => a > b ? a : b);
  final chartMax = maxY < 1 ? 1.0 : maxY * 1.2;
  final minWidth = _dashboardChartMinWidthForCount(labels.length, perItem: 74);

  return _dashboardScrollableChart(
    minWidth: minWidth,
    child: BarChart(
      BarChartData(
        maxY: chartMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: t.border.withValues(alpha: 0.22), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return DefaultTextStyle(
                  style: TextStyle(color: t.textMuted),
                  child: _dashboardAxisLabel(
                    meta: meta,
                    label: labels[i],
                    angle: -0.45,
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(values.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                width: barWidth,
                color: palette[i % palette.length],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    ),
  );
}

class DashboardPieSlice {
  const DashboardPieSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

Widget dashboardPieChart({
  required BuildContext context,
  required List<DashboardPieSlice> slices,
  String emptyLabel = 'OK',
}) {
  final t = context.pharmaTokens;
  final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
  final activeSlices = slices.where((slice) => slice.value > 0).toList(growable: false);

  if (total <= 0 && activeSlices.isEmpty) {
    return _dashboardChartEmptyState(context);
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 280.0;
      final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 280.0;
      final chartDim = math.min(maxW, math.max(maxH - 40, 120));
      final sectionRadius = (chartDim * 0.18).clamp(20.0, 56.0);
      final centerSpaceRadius = (chartDim * 0.12).clamp(12.0, 36.0);

      final sections = total <= 0
          ? [
              PieChartSectionData(
                value: 1,
                color: t.brandGreen.withValues(alpha: 0.35),
                title: emptyLabel,
                radius: sectionRadius,
                titleStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: t.textMuted,
                ),
              ),
            ]
          : activeSlices
              .map(
                (slice) => PieChartSectionData(
                  value: slice.value,
                  color: slice.color,
                  title: '',
                  radius: sectionRadius,
                ),
              )
              .toList(growable: false);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: centerSpaceRadius,
                sections: sections,
              ),
            ),
          ),
          if (activeSlices.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _dashboardChartLegend(
              items: [
                for (final slice in activeSlices)
                  (slice.label, slice.color),
              ],
            ),
          ],
        ],
      );
    },
  );
}

Widget dashboardSimpleTable({
  String? title,
  required List<String> headers,
  required List<List<String>> rows,
  List<DashboardTableColumn>? columns,
  int? sortColumnIndex,
  bool sortAscending = true,
  ValueSetter<int>? onSortColumn,
  String emptySubtitle = 'Sem resultados para os filtros selecionados.',
}) {
  final tableColumns = columns ??
      headers.map((header) => DashboardTableColumn(label: header)).toList(growable: false);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (title != null) ...[
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (rows.isEmpty)
        DashboardEmptyState(
          subtitle: emptySubtitle,
        )
      else
        EnterpriseDataTable(
          showCheckboxColumn: false,
          sortColumnIndex: sortColumnIndex,
          sortAscending: sortAscending,
          columns: List.generate(tableColumns.length, (index) {
            final column = tableColumns[index];
            return DataColumn(
              label: Text(column.label),
              onSort: column.sortKey == null || onSortColumn == null
                  ? null
                  : (_, _) => onSortColumn(index),
            );
          }),
          rowCount: rows.length,
          rowBuilder: (context, index) => DataRow(
            cells: rows[index].map((cell) => DataCell(Text(cell))).toList(),
          ),
        ),
    ],
  );
}

class DashboardPaginatedTable extends StatefulWidget {
  const DashboardPaginatedTable({
    super.key,
    required this.title,
    required this.loadPage,
    required this.rowBuilder,
    required this.reloadKey,
    this.headers = const [],
    this.columns,
    this.initialPageSize = 10,
    this.initialSortBy,
    this.initialSortDir = 'desc',
    this.emptySubtitle = 'Sem resultados para os filtros selecionados.',
  });

  final String title;
  final List<String> headers;
  final List<DashboardTableColumn>? columns;
  final Future<DashboardPagedTableResult> Function(
    int page,
    int pageSize,
    String? sortBy,
    String sortDir,
  ) loadPage;
  final List<String> Function(Map<String, dynamic> row) rowBuilder;
  final Object reloadKey;
  final int initialPageSize;
  final String? initialSortBy;
  final String initialSortDir;
  final String emptySubtitle;

  @override
  State<DashboardPaginatedTable> createState() => _DashboardPaginatedTableState();
}

class _DashboardPaginatedTableState extends State<DashboardPaginatedTable> {
  DashboardPagedTableResult? _result;
  Object? _error;
  var _page = 1;
  late int _pageSize = widget.initialPageSize;
  late String? _sortBy = widget.initialSortBy;
  late String _sortDir = widget.initialSortDir;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant DashboardPaginatedTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadKey != widget.reloadKey) {
      _page = 1;
      _pageSize = widget.initialPageSize;
      _sortBy = widget.initialSortBy;
      _sortDir = widget.initialSortDir;
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.loadPage(_page, _pageSize, _sortBy, _sortDir);
      if (!mounted) return;
      setState(() {
        _result = result;
        _page = result.page;
        _pageSize = result.pageSize;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _toggleSort(int index) {
    final columns = widget.columns ??
        widget.headers.map((header) => DashboardTableColumn(label: header)).toList(growable: false);
    if (index < 0 || index >= columns.length) return;
    final sortKey = columns[index].sortKey;
    if (sortKey == null) return;
    setState(() {
      if (_sortBy == sortKey) {
        _sortDir = _sortDir == 'asc' ? 'desc' : 'asc';
      } else {
        _sortBy = sortKey;
        _sortDir = 'asc';
      }
      _page = 1;
    });
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final tableColumns = widget.columns ??
        widget.headers.map((header) => DashboardTableColumn(label: header)).toList(growable: false);
    final sortColumnIndex = _sortBy == null
        ? null
        : tableColumns.indexWhere((column) => column.sortKey == _sortBy);

    if (_loading && _result == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          const DashboardLoadingState(kpiCount: 0),
        ],
      );
    }

    if (_error != null && _result == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          Text('Não foi possível carregar a tabela: $_error'),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: _fetch, child: const Text('Tentar novamente')),
        ],
      );
    }

    final result = _result ??
        DashboardPagedTableResult(
          items: const [],
          page: _page,
          pageSize: _pageSize,
          hasMore: false,
        );

    final rows = result.items.map(widget.rowBuilder).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (_sortBy != null)
              Text(
                _sortDir == 'asc' ? 'Ordem ascendente' : 'Ordem descendente',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: t.textMuted,
                    ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          [
            '${rows.length} itens nesta página',
            if (result.totalCount != null) '${result.totalCount} no total',
            if (result.totalPages != null) 'página ${result.page} de ${result.totalPages}',
          ].join(' · '),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: t.textMuted,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_loading && _result != null)
          const LinearProgressIndicator(minHeight: 2),
        dashboardSimpleTable(
          headers: widget.headers,
          rows: rows,
          columns: tableColumns,
          sortColumnIndex: sortColumnIndex != null && sortColumnIndex >= 0
              ? sortColumnIndex
              : null,
          sortAscending: _sortDir == 'asc',
          onSortColumn: _toggleSort,
          emptySubtitle: widget.emptySubtitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        MovimentacoesPagination(
          page: result.page,
          pageSize: result.pageSize,
          hasMore: result.hasMore,
          isBusy: _loading,
          onPrev: result.hasPrevious
              ? () {
                  _page = result.page - 1;
                  _fetch();
                }
              : null,
          onNext: result.hasMore
              ? () {
                  _page = result.page + 1;
                  _fetch();
                }
              : null,
          onPageSizeChanged: (value) {
            _page = 1;
            _pageSize = value;
            _fetch();
          },
        ),
      ],
    );
  }
}

Future<void> dashboardReportExport({
  required WidgetRef ref,
  required String path,
  required DashboardQuery query,
  String format = 'csv',
}) async {
  final controller = ref.read(reportControllerProvider.notifier);
  final params = query.toParams();

  switch (format) {
    case 'excel':
      await controller.exportExcel(path: path, queryParameters: params);
      return;
    case 'pdf':
      await controller.downloadPdf(path: path, queryParameters: params);
      return;
    case 'csv':
    default:
      await controller.exportCsv(path: path, queryParameters: params);
  }
}
