import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/ui/layout/pharma_screen_layout.dart';
import '../providers/invoice_list_provider.dart';

class InvoicesToolbarV2 extends ConsumerWidget {
  const InvoicesToolbarV2({
    super.key,
    required this.searchController,
    required this.state,
  });

  final TextEditingController searchController;
  final InvoiceListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isMobile = PharmaScreenLayout.isMobile(context);
    final isTablet = PharmaScreenLayout.isTablet(context);
    final query = ref.read(invoiceListProvider).query;

    return Material(
      color: t.bgPrimary,
      borderRadius: BorderRadius.circular(t.radiusMd),
      elevation: 0,
      child: Padding(
        padding: isMobile ? EdgeInsets.all(s.md) : t.density.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isMobile || isTablet)
              Row(
                children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) =>
                        ref.read(invoiceListProvider.notifier).search(value),
                    decoration: InputDecoration(
                      isDense: isMobile,
                      hintText: 'Pesquisar fatura',
                      prefixIcon: Icon(Icons.search_rounded, color: t.brandBlue),
                      suffixIcon: query.search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                searchController.clear();
                                ref.read(invoiceListProvider.notifier).clearSearch();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                if (isTablet) ...[
                  SizedBox(width: s.md),
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded),
                    onPressed: () {},
                  ),
                ],
              ],
            ),
            if (!isMobile && !isTablet)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) =>
                          ref.read(invoiceListProvider.notifier).search(value),
                      decoration: InputDecoration(
                        hintText: 'Pesquisar fatura',
                        prefixIcon: Icon(Icons.search_rounded, color: t.brandBlue),
                        suffixIcon: query.search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  searchController.clear();
                                  ref.read(invoiceListProvider.notifier).clearSearch();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(width: s.md),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.filter_list_rounded),
                    label: const Text('Filtrar'),
                    onPressed: () {},
                  ),
                  SizedBox(width: s.sm),
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Actualizar'),
                    onPressed: state.isLoading
                        ? null
                        : () => ref.read(invoiceListProvider.notifier).refresh(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class InvoicesKpiGrid extends StatelessWidget {
  const InvoicesKpiGrid({
    super.key,
    required this.totalInvoices,
    required this.paid,
    required this.pending,
    required this.cancelled,
    this.hasFilters = false,
  });

  final int totalInvoices;
  final int paid;
  final int pending;
  final int cancelled;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isMobile = PharmaScreenLayout.isMobile(context);
    final isTablet = PharmaScreenLayout.isTablet(context);

    final items = [
      (
        'Total',
        '$totalInvoices',
        t.brandBlue,
        Icons.receipt_long_rounded,
      ),
      (
        'Pagas',
        '$paid',
        t.brandGreen,
        Icons.check_circle_outline_rounded,
      ),
      (
        'Pendentes',
        '$pending',
        t.posWarning,
        Icons.access_time_rounded,
      ),
      (
        'Anuladas',
        '$cancelled',
        t.posDanger,
        Icons.block_rounded,
      ),
    ];

    final crossAxisCount = isMobile ? 2 : (isTablet ? 4 : 4);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: s.sm,
        crossAxisSpacing: s.sm,
        childAspectRatio: isMobile ? 2.2 : 2.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final (title, value, color, icon) = items[index];
        return _KpiCard(
          title: title,
          value: value,
          color: color,
          icon: icon,
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.55),
      ),
      child: Padding(
        padding: EdgeInsets.all(s.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(s.sm),
              decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(t.radiusMd),
            ),
            child: Icon(icon, color: color, size: t.iconSm),
          ),
            SizedBox(width: s.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: t.textMuted,
                        ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
