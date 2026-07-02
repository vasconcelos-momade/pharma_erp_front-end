import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/pharma_surface.dart';
import '../../../../../core/theme/spacing.dart';

class ProdutoPagination extends StatelessWidget {
  const ProdutoPagination({
    super.key,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  static const _pageSizeOptions = [10, 20, 50, 100];

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);
    final totalPages = (totalCount / pageSize).ceil();
    if (totalPages <= 1 && totalCount == 0) return const SizedBox.shrink();

    final start = ((page - 1) * pageSize) + 1;
    final end = (start + pageSize - 1).clamp(0, totalCount);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: s.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando $start–$end de $totalCount registros',
            style: theme.textTheme.labelLarge?.copyWith(color: t.textMuted),
          ),
          Row(
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _pageSizeOptions.contains(pageSize)
                      ? pageSize
                      : _pageSizeOptions.first,
                  isDense: true,
                  icon: Icon(Icons.arrow_drop_down, size: t.iconSm, color: t.textMuted),
                  style: theme.textTheme.labelLarge?.copyWith(color: t.textPrimary),
                  items: _pageSizeOptions
                      .map(
                        (size) => DropdownMenuItem(
                          value: size,
                          child: Text('$size'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) onPageSizeChanged(val);
                  },
                ),
              ),
              SizedBox(width: s.lg),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, size: t.iconSm),
                    onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
                    style: pharmaInstantButtonStyle(
                      IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(
                          t.minTouchTarget * 0.65,
                          t.minTouchTarget * 0.65,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: t.minTouchTarget * 0.65,
                      minHeight: t.minTouchTarget * 0.65,
                    ),
                  ),
                  ..._buildPageNumbers(context, totalPages, t, theme),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, size: t.iconSm),
                    onPressed:
                        page < totalPages ? () => onPageChanged(page + 1) : null,
                    style: pharmaInstantButtonStyle(
                      IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(
                          t.minTouchTarget * 0.65,
                          t.minTouchTarget * 0.65,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: t.minTouchTarget * 0.65,
                      minHeight: t.minTouchTarget * 0.65,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(
    BuildContext context,
    int totalPages,
    PharmaTokens t,
    ThemeData theme,
  ) {
    final s = context.spacing;
    final widgets = <Widget>[];
    final pages = <int>{1, totalPages, page, page - 1, page + 1};

    final sortedPages = pages.where((p) => p >= 1 && p <= totalPages).toList()
      ..sort();

    int? lastPage;
    for (final p in sortedPages) {
      if (lastPage != null && p - lastPage > 1) {
        widgets.add(Padding(
          padding: EdgeInsets.symmetric(horizontal: s.xs),
          child: Text('…', style: TextStyle(color: t.textMuted)),
        ));
      }

      final isCurrent = p == page;
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: s.xxs / 2),
          child: isCurrent
              ? FilledButton(
                  onPressed: () {},
                  style: pharmaInstantButtonStyle(
                    FilledButton.styleFrom(
                      minimumSize: Size(t.minTouchTarget * 0.7, t.minTouchTarget * 0.7),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  child: Text(
                    '$p',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : OutlinedButton(
                  onPressed: () => onPageChanged(p),
                  style: pharmaInstantButtonStyle(
                    OutlinedButton.styleFrom(
                      minimumSize: Size(t.minTouchTarget * 0.7, t.minTouchTarget * 0.7),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  child: Text(
                    '$p',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
        ),
      );

      lastPage = p;
    }

    return widgets;
  }
}
