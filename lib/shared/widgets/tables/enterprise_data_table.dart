import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../responsive/breakpoints.dart';
import '../../responsive/pharma_screen_layout.dart';

typedef EnterpriseRowBuilder = DataRow Function(BuildContext context, int index);

String _describeCellWidget(Widget? widget) {
  if (widget == null) return '';
  if (widget is Text) {
    return widget.data ?? widget.textSpan?.toPlainText() ?? '';
  }
  if (widget is RichText) {
    return widget.text.toPlainText();
  }
  if (widget is Chip) {
    return _describeCellWidget(widget.label);
  }
  if (widget is Icon || widget is IconButton) return '';
  if (widget is Row) {
    return widget.children.map(_describeCellWidget).where((s) => s.trim().isNotEmpty).join(' · ');
  }
  if (widget is Column) {
    return widget.children.map(_describeCellWidget).where((s) => s.trim().isNotEmpty).join(' · ');
  }
  if (widget is Padding) {
    return _describeCellWidget(widget.child);
  }
  if (widget is Center) {
    return _describeCellWidget(widget.child);
  }
  return '';
}

/// Tabela enterprise: em **mobile** lista densa tipo cartão; em tablet/desktop `DataTable`.
class EnterpriseDataTable extends StatelessWidget {
  const EnterpriseDataTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.rowBuilder,
    this.adaptive = true,
    this.showCheckboxColumn = true,
  });

  final List<DataColumn> columns;
  final int rowCount;
  final EnterpriseRowBuilder rowBuilder;
  final bool adaptive;
  final bool showCheckboxColumn;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return LayoutBuilder(
      builder: (context, c) {
        final useCards = adaptive && PharmaScreenLayout.isMobile(context);
        final boundedHeight = c.hasBoundedHeight && c.maxHeight.isFinite;

        if (useCards) {
          final boundedHeight = c.hasBoundedHeight && c.maxHeight.isFinite;
          return Material(
            color: Colors.transparent,
            child: ListView.separated(
              shrinkWrap: !boundedHeight,
              physics: boundedHeight
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: rowCount,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, i) {
                final row = rowBuilder(context, i);
                final parts = row.cells.map((e) => _describeCellWidget(e.child)).where((s) => s.isNotEmpty).toList();
                final title = parts.isNotEmpty ? parts.first : '—';
                final rest = parts.length > 1 ? parts.sublist(1).join(' · ') : null;
                return Material(
                  color: t.card,
                  borderRadius: BorderRadius.circular(t.radiusMd),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(t.radiusMd),
                    onTap: row.onSelectChanged != null ? () => row.onSelectChanged!(true) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                        color: t.textPrimary,
                                      ),
                                ),
                                if (rest != null && rest.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    rest,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                          color: t.textMuted,
                                          height: 1.25,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, size: 20, color: t.textMuted),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        return Material(
          color: t.card,
          borderRadius: BorderRadius.circular(t.radiusMd),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(t.radiusMd),
              border: Border.all(color: t.border.withValues(alpha: 0.55)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Scrollbar(
              thumbVisibility: c.maxWidth < Breakpoints.tablet,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: c.maxWidth),
                  child: Scrollbar(
                    thumbVisibility: boundedHeight,
                    notificationPredicate: (notification) =>
                        notification.metrics.axis == Axis.vertical,
                    child: SingleChildScrollView(
                      physics: boundedHeight
                          ? const ClampingScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      child: DataTable(
                        showCheckboxColumn: showCheckboxColumn,
                        headingRowColor: WidgetStatePropertyAll(
                          t.bgSecondary.withValues(alpha: 0.92),
                        ),
                        dataRowMinHeight:
                            PharmaScreenLayout.isTablet(context) ? 44 : 40,
                        dataRowMaxHeight: 72,
                        horizontalMargin: PharmaScreenLayout.isDesktop(context)
                            ? AppSpacing.lg
                            : AppSpacing.md,
                        columnSpacing: PharmaScreenLayout.isDesktop(context)
                            ? AppSpacing.xxl
                            : AppSpacing.lg,
                        columns: columns,
                        rows: List.generate(
                          rowCount,
                          (i) => rowBuilder(context, i),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
