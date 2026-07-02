import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';

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
    final s = context.spacing;
    final screen = context.pharmaScreen;
    final pageSizeOptions = const [10, 25, 50, 100];

    if (screen == PharmaScreenSize.mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Página $page',
                style: Theme.of(context).textTheme.erpLabel,
              ),
              const Spacer(),
              DropdownButton<int>(
                value: pageSizeOptions.contains(pageSize)
                    ? pageSize
                    : pageSizeOptions.first,
                items: pageSizeOptions
                    .map(
                      (value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value itens'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: isBusy
                    ? null
                    : (value) => value != null ? onPageSizeChanged?.call(value) : null,
              ),
            ],
          ),
          SizedBox(height: s.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onPrev,
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Anterior'),
                ),
              ),
              SizedBox(width: s.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isBusy || !hasMore ? null : onNext,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Próxima'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(
          'Página $page',
          style: Theme.of(context).textTheme.erpLabel,
        ),
        SizedBox(width: s.lg),
        Text(
          hasMore ? 'Mais resultados disponíveis' : 'Fim da lista',
          style: Theme.of(context).textTheme.erpCaption.copyWith(
                color: context.pharmaTokens.textMuted,
              ),
        ),
        const Spacer(),
        DropdownButton<int>(
          value: pageSizeOptions.contains(pageSize)
              ? pageSize
              : pageSizeOptions.first,
          items: pageSizeOptions
              .map(
                (value) => DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value / página'),
                ),
              )
              .toList(growable: false),
          onChanged: isBusy
              ? null
              : (value) => value != null ? onPageSizeChanged?.call(value) : null,
        ),
        SizedBox(width: s.md),
        OutlinedButton.icon(
          onPressed: isBusy ? null : onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
          label: const Text('Anterior'),
        ),
        SizedBox(width: s.sm),
        FilledButton.icon(
          onPressed: isBusy || !hasMore ? null : onNext,
          icon: const Icon(Icons.chevron_right_rounded),
          label: const Text('Próxima'),
        ),
      ],
    );
  }
}
