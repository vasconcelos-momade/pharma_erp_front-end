import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';

class InvoicePagination extends StatelessWidget {
  const InvoicePagination({
    super.key,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.isBusy,
    this.onPrev,
    this.onNext,
    this.onPageSizeChanged,
  });

  final int page;
  final int pageSize;
  final bool hasMore;
  final bool isBusy;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int>? onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Material(
      color: t.bgPrimary,
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!isMobile)
              Row(
                children: [
                  Text(
                    'Página $page',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: t.textMuted,
                        ),
                  ),
                  SizedBox(width: s.md),
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<int>(
                      value: pageSize,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('10')),
                        DropdownMenuItem(value: 20, child: Text('20')),
                        DropdownMenuItem(value: 50, child: Text('50')),
                        DropdownMenuItem(value: 100, child: Text('100')),
                      ],
                      onChanged: isBusy
                          ? null
                          : (value) {
                              if (value != null && onPageSizeChanged != null) {
                                onPageSizeChanged!(value);
                              }
                            },
                    ),
                  ),
                ],
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: isBusy ? null : onPrev,
                ),
                SizedBox(width: s.sm),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: isBusy || !hasMore ? null : onNext,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
