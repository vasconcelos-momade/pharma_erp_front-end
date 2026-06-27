import 'dart:convert';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/browser_file_handler.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import 'dashboard_state_widgets.dart';

class DashboardExportSection {
  const DashboardExportSection({
    required this.title,
    required this.headers,
    required this.rows,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;
}

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
  double height = 220,
}) {
  final t = context.pharmaTokens;
  if (points.isEmpty) {
    return SizedBox(
      height: height,
      child: Center(child: Text('Sem dados no período', style: TextStyle(color: t.textMuted))),
    );
  }

  final spots = <FlSpot>[];
  var maxY = 0.0;
  for (var i = 0; i < points.length; i++) {
    final y = (points[i][valueKey] as num?)?.toDouble() ?? 0;
    if (y > maxY) maxY = y;
    spots.add(FlSpot(i.toDouble(), y));
  }
  final chartMax = maxY < 1 ? 1.0 : maxY * 1.15;

  return SizedBox(
    height: height,
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
                      return Text(
                        dashLabel(points[i][labelKey], max: 6),
                        style: TextStyle(fontSize: 9, color: t.textMuted),
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
  return Material(
    color: t.card,
    borderRadius: BorderRadius.circular(t.radiusMd),
    child: Container(
      padding: t.density.cardPadding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: t.textMuted,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
          ),
          SizedBox(height: t.density.md),
          child,
        ],
      ),
    ),
  );
}

Widget dashboardBarChart({
  required BuildContext context,
  required List<Map<String, dynamic>> points,
  required String valueKey,
  required String labelKey,
  double height = 240,
  Color? color,
}) {
  final t = context.pharmaTokens;
  if (points.isEmpty) {
    return SizedBox(
      height: height,
      child: Center(child: Text('Sem dados no período', style: TextStyle(color: t.textMuted))),
    );
  }

  final values = points
      .map((point) => (point[valueKey] as num?)?.toDouble() ?? 0)
      .toList(growable: false);
  final maxY = values.fold<double>(0, (a, b) => a > b ? a : b);
  final chartMax = maxY < 1 ? 1.0 : maxY * 1.2;

  return SizedBox(
    height: height,
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
                return Text(
                  dashLabel(points[i][labelKey]),
                  style: TextStyle(fontSize: 9, color: t.textMuted),
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
  double height = 240,
}) {
  final t = context.pharmaTokens;
  if (points.isEmpty) {
    return SizedBox(
      height: height,
      child: Center(child: Text('Sem dados no período', style: TextStyle(color: t.textMuted))),
    );
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

  return SizedBox(
    height: height,
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
  );
}

Widget dashboardIndexedBarChart({
  required BuildContext context,
  required List<double> values,
  required List<String> labels,
  List<Color>? barColors,
  double height = 220,
  double barWidth = 22,
}) {
  final t = context.pharmaTokens;
  if (values.isEmpty) {
    return SizedBox(
      height: height,
      child: Center(child: Text('Sem dados no período', style: TextStyle(color: t.textMuted))),
    );
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

  return SizedBox(
    height: height,
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
                return Text(
                  labels[i],
                  style: TextStyle(fontSize: 9, color: t.textMuted),
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
  double height = 220,
  String emptyLabel = 'OK',
}) {
  final t = context.pharmaTokens;
  final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
  final sections = total <= 0
      ? [
          PieChartSectionData(
            value: 1,
            color: t.brandGreen.withValues(alpha: 0.35),
            title: emptyLabel,
            radius: 48,
            titleStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t.textMuted),
          ),
        ]
      : slices
          .where((slice) => slice.value > 0)
          .map(
            (slice) => PieChartSectionData(
              value: slice.value,
              color: slice.color,
              title: slice.label,
              radius: 48,
              titleStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: t.textPrimary),
            ),
          )
          .toList(growable: false);

  if (sections.isEmpty) {
    return SizedBox(
      height: height,
      child: Center(child: Text('Sem dados no período', style: TextStyle(color: t.textMuted))),
    );
  }

  return SizedBox(
    height: height,
    child: PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 28,
        sections: sections,
      ),
    ),
  );
}

Widget dashboardSimpleTable({
  required String title,
  required List<String> headers,
  required List<List<String>> rows,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: AppSpacing.sm),
      if (rows.isEmpty)
        DashboardEmptyState(
          title: title,
          subtitle: 'Sem registos para os filtros seleccionados.',
        )
      else
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: EnterpriseDataTable(
                  showCheckboxColumn: false,
                  columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
                  rowCount: rows.length,
                  rowBuilder: (context, index) => DataRow(
                    cells: rows[index].map((cell) => DataCell(Text(cell))).toList(),
                  ),
                ),
              ),
            );
          },
        ),
    ],
  );
}

class DashboardPaginatedTable extends StatefulWidget {
  const DashboardPaginatedTable({
    super.key,
    required this.title,
    required this.headers,
    required this.loadPage,
    required this.rowBuilder,
    required this.reloadKey,
    this.initialPageSize = 10,
  });

  final String title;
  final List<String> headers;
  final Future<DashboardPagedTableResult> Function(int page, int pageSize) loadPage;
  final List<String> Function(Map<String, dynamic> row) rowBuilder;
  final Object reloadKey;
  final int initialPageSize;

  @override
  State<DashboardPaginatedTable> createState() => _DashboardPaginatedTableState();
}

class _DashboardPaginatedTableState extends State<DashboardPaginatedTable> {
  DashboardPagedTableResult? _result;
  Object? _error;
  var _page = 1;
  late int _pageSize = widget.initialPageSize;
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
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.loadPage(_page, _pageSize);
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

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    if (_loading && _result == null) {
      return const Center(child: CircularProgressIndicator());
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
        if (_loading && _result != null)
          const LinearProgressIndicator(minHeight: 2),
        dashboardSimpleTable(title: widget.title, headers: widget.headers, rows: rows),
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
        if (result.totalCount != null || result.totalPages != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              [
                if (result.totalCount != null) '${result.totalCount} registos',
                if (result.totalPages != null)
                  'página ${result.page} de ${result.totalPages}',
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: t.textMuted,
                  ),
            ),
          ),
      ],
    );
  }
}

Future<void> dashboardExportCsv({
  required String fileName,
  Map<String, dynamic>? summary,
  required List<DashboardExportSection> sections,
}) async {
  final buffer = StringBuffer();

  if (summary != null && summary.isNotEmpty) {
    buffer.writeln('Resumo');
    summary.forEach((key, value) {
      buffer.writeln('${_csv(key)},${_csv(value)}');
    });
    buffer.writeln();
  }

  for (var i = 0; i < sections.length; i++) {
    final section = sections[i];
    buffer.writeln(_csv(section.title));
    buffer.writeln(section.headers.map(_csv).join(','));
    for (final row in section.rows) {
      buffer.writeln(row.map(_csv).join(','));
    }
    if (i < sections.length - 1) {
      buffer.writeln();
    }
  }

  await BrowserFileHandler.downloadBytes(
    bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
    fileName: fileName,
    contentType: 'text/csv;charset=utf-8',
  );
}

String _csv(dynamic value) {
  final raw = (value ?? '').toString().replaceAll('"', '""');
  return '"$raw"';
}
