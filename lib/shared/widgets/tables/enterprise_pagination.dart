import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../../core/theme/pharma_surface.dart';

/// Paginação enterprise unificada: resumo, itens por página e navegação numerada.
class EnterprisePagination extends StatelessWidget {
  const EnterprisePagination({
    super.key,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.totalCount,
    this.hasMore,
    this.itemsOnPage,
    this.isBusy = false,
    this.itemLabel = 'registros',
  });

  final int page;
  final int pageSize;
  final int? totalCount;
  final bool? hasMore;
  final int? itemsOnPage;
  final bool isBusy;
  final String itemLabel;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  static const pageSizeOptions = [10, 20, 50, 100];

  bool get _hasKnownTotal => totalCount != null;

  int get _resolvedTotalCount {
    if (totalCount != null) return totalCount!;
    if (hasMore == true) return page * pageSize + 1;
    final countOnPage = itemsOnPage ?? pageSize;
    return ((page - 1) * pageSize) + countOnPage;
  }

  int get _start => totalCount == 0 ? 0 : ((page - 1) * pageSize) + 1;

  int get _end {
    if (totalCount != null) {
      return (_start + pageSize - 1).clamp(0, totalCount!);
    }
    if (hasMore == true) return page * pageSize;
    final countOnPage = itemsOnPage ?? pageSize;
    return _start + countOnPage - 1;
  }

  int get _totalPages {
    if (!_hasKnownTotal) return page + (hasMore == true ? 1 : 0);
    return (totalCount! / pageSize).ceil();
  }

  bool get _canGoBack => !isBusy && page > 1;

  bool get _canGoForward {
    if (isBusy) return false;
    if (_hasKnownTotal) return page < _totalPages;
    return hasMore == true;
  }

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return const SizedBox.shrink();
    }
    if (_hasKnownTotal && _totalPages <= 1 && totalCount == 0) {
      return const SizedBox.shrink();
    }
    if (!_hasKnownTotal && page == 1 && hasMore != true && (itemsOnPage ?? 0) == 0) {
      return const SizedBox.shrink();
    }

    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final summaryText = _hasKnownTotal
        ? 'Mostrando $_start-$_end de $_resolvedTotalCount $itemLabel'
        : 'Mostrando $_start-$_end $itemLabel';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: s.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useStackedLayout = constraints.maxWidth < 920;

          final summary = Wrap(
            spacing: s.md,
            runSpacing: s.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                summaryText,
                style: theme.textTheme.erpLabel.copyWith(color: t.textMuted),
              ),
              _PageSizeSelector(
                pageSize: pageSize,
                options: pageSizeOptions,
                enabled: !isBusy,
                onChanged: onPageSizeChanged,
              ),
            ],
          );

          final pagination = Align(
            alignment: Alignment.centerRight,
            child: PharmaSurface(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(t.radius3xl),
              border: Border.all(
                color: scheme.outline.withValues(alpha: isDark ? 0.6 : 0.8),
              ),
              clipBehavior: Clip.antiAlias,
              child: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PaginationSegmentButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _canGoBack,
                      onPressed: _canGoBack ? () => onPageChanged(page - 1) : null,
                    ),
                    for (final item in _buildPageItems()) ...[
                      _PaginationDivider(color: scheme.outline.withValues(alpha: 0.18)),
                      if (item is int)
                        _PaginationSegmentButton(
                          label: '$item',
                          selected: item == page,
                          enabled: !isBusy,
                          onPressed: item == page || isBusy
                              ? null
                              : () => onPageChanged(item),
                        )
                      else
                        _PaginationGap(
                          label: item as String,
                          textColor: t.textMuted,
                        ),
                    ],
                    _PaginationDivider(color: scheme.outline.withValues(alpha: 0.18)),
                    _PaginationSegmentButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _canGoForward,
                      onPressed: _canGoForward ? () => onPageChanged(page + 1) : null,
                    ),
                  ],
                ),
              ),
            ),
          );

          if (useStackedLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                summary,
                SizedBox(height: s.sm),
                pagination,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: summary),
              SizedBox(width: s.lg),
              pagination,
            ],
          );
        },
      ),
    );
  }

  List<Object> _buildPageItems() {
    if (!_hasKnownTotal) {
      return [page];
    }

    final totalPages = _totalPages;
    final items = <Object>[];
    final pages = <int>{1, totalPages, page, page - 1, page + 1};
    final sortedPages = pages.where((p) => p >= 1 && p <= totalPages).toList()..sort();

    int? lastPage;
    for (final p in sortedPages) {
      if (lastPage != null && p - lastPage > 1) {
        items.add('...');
      }
      items.add(p);
      lastPage = p;
    }
    return items;
  }
}

class _PageSizeSelector extends StatelessWidget {
  const _PageSizeSelector({
    required this.pageSize,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  final int pageSize;
  final List<int> options;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final theme = Theme.of(context);
    final selectedValue = options.contains(pageSize) ? pageSize : options.first;
    final valueStyle = theme.textTheme.erpLabel.copyWith(color: t.textSecondary);

    return PharmaSurface(
      padding: EdgeInsets.symmetric(
        horizontal: t.density.sm,
        vertical: t.density.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Itens por pagina',
            style: theme.textTheme.erpLabel.copyWith(color: t.textMuted),
          ),
          SizedBox(width: context.spacing.xs),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedValue,
              isDense: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: t.iconSm,
                color: t.textMuted,
              ),
              style: valueStyle,
              items: options
                  .map(
                    (size) => DropdownMenuItem<int>(
                      value: size,
                      child: Text('$size', style: valueStyle),
                    ),
                  )
                  .toList(growable: false),
              onChanged: enabled
                  ? (value) {
                      if (value != null) onChanged(value);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationDivider extends StatelessWidget {
  const _PaginationDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(width: 1, thickness: 1, color: color);
  }
}

class _PaginationGap extends StatelessWidget {
  const _PaginationGap({
    required this.label,
    required this.textColor,
  });

  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: DesignMetrics.minTouchTarget,
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.erpLabel.copyWith(color: textColor),
        ),
      ),
    );
  }
}

class _PaginationSegmentButton extends StatelessWidget {
  const _PaginationSegmentButton({
    this.label,
    this.icon,
    this.selected = false,
    this.enabled = true,
    this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBackground = scheme.primary.withValues(alpha: isDark ? 0.22 : 0.12);
    final resolvedForeground = selected
        ? scheme.primary.withValues(alpha: isDark ? 0.9 : 0.82)
        : enabled
            ? t.textMuted
            : t.textMuted.withValues(alpha: 0.5);

    return SizedBox(
      width: DesignMetrics.minTouchTarget,
      height: DesignMetrics.minTouchTarget,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: pharmaInstantButtonStyle(
          TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.square(DesignMetrics.minTouchTarget),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(t.radiusMd),
            ),
            backgroundColor: selected ? activeBackground : scheme.surface.withValues(alpha: 0),
            foregroundColor: resolvedForeground,
            disabledForegroundColor: t.textMuted.withValues(alpha: 0.5),
          ),
        ),
        child: icon != null
            ? Icon(icon, size: t.iconSm)
            : Text(
                label!,
                style: Theme.of(context).textTheme.erpLabel.copyWith(
                      color: resolvedForeground,
                    ),
              ),
      ),
    );
  }
}
