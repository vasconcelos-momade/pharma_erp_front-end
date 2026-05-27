import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/ui/layout/pharma_screen_layout.dart';
import '../../domain/entities/invoice_summary.dart';
import 'invoice_formatters.dart';
import 'invoice_status_badge.dart';

class InvoicesResults extends StatelessWidget {
  const InvoicesResults({
    super.key,
    required this.invoices,
    required this.onView,
    required this.onCancel,
    this.embedded = false,
  });

  final List<InvoiceSummary> invoices;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCards = PharmaScreenLayout.isMobile(context) || constraints.maxWidth < 860;
        if (useCards) {
          return InvoiceCardList(
            invoices: invoices,
            onView: onView,
            onCancel: onCancel,
            embedded: embedded,
          );
        }
        return InvoiceDesktopTable(
          invoices: invoices,
          onView: onView,
          onCancel: onCancel,
        );
      },
    );
  }
}

class InvoiceCardList extends StatelessWidget {
  const InvoiceCardList({
    super.key,
    required this.invoices,
    required this.onView,
    required this.onCancel,
    this.embedded = false,
  });

  final List<InvoiceSummary> invoices;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return ListView.separated(
      padding: embedded ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: s.lg),
      physics: embedded ? const NeverScrollableScrollPhysics() : null,
      shrinkWrap: embedded,
      itemBuilder: (context, index) => InvoiceCard(
        invoice: invoices[index],
        onView: onView,
        onCancel: onCancel,
      ),
      separatorBuilder: (context, index) => SizedBox(height: s.sm),
      itemCount: invoices.length,
    );
  }
}

class InvoiceCard extends StatelessWidget {
  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onView,
    required this.onCancel,
  });

  final InvoiceSummary invoice;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return InkWell(
      onTap: () => onView(invoice),
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: Container(
        padding: EdgeInsets.all(s.md),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(t.radiusMd),
          border: Border.all(color: t.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.numero,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      SizedBox(height: s.xs),
                      Text(
                        invoice.cliente?.nome ?? 'Consumidor final',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: t.textMuted,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InvoiceStatusBadge(status: invoice.estado),
              ],
            ),
            SizedBox(height: s.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MetaChip(label: formatDateTime(invoice.createdAt)),
                Text(
                  formatMoney(invoice.total),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: t.brandGreen,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            SizedBox(height: s.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onView(invoice),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver'),
                ),
                SizedBox(width: s.sm),
                FilledButton.icon(
                  onPressed: invoice.isCancelled ? null : () => onCancel(invoice),
                  icon: const Icon(Icons.block_rounded),
                  label: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InvoiceDesktopTable extends StatelessWidget {
  const InvoiceDesktopTable({
    super.key,
    required this.invoices,
    required this.onView,
    required this.onCancel,
  });

  final List<InvoiceSummary> invoices;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(t.radiusXl),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: LayoutBuilder(
        builder: (context, c) {
          final dense = c.maxWidth < 1100;
          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: c.maxWidth),
                child: DataTable(
                  headingRowColor:
                      WidgetStatePropertyAll(t.bgSecondary.withValues(alpha: 0.92)),
                  dataRowMinHeight: dense ? 48 : 54,
                  dataRowMaxHeight: dense ? 54 : 62,
                  horizontalMargin: dense ? s.md : s.lg,
                  columnSpacing: dense ? s.lg : s.xl,
                  columns: const [
                    DataColumn(label: Text('Nº')),
                    DataColumn(label: Text('Cliente')),
                    DataColumn(label: Text('Data')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Ações')),
                  ],
                  rows: invoices.map((invoice) {
                    return DataRow(
                      cells: [
                        DataCell(Text(invoice.numero)),
                        DataCell(Text(invoice.cliente?.nome ?? 'Consumidor final')),
                        DataCell(Text(formatDateTime(invoice.createdAt))),
                        DataCell(
                          Text(
                            formatMoney(invoice.total),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: t.brandGreen,
                                ),
                          ),
                        ),
                        DataCell(InvoiceStatusBadge(status: invoice.estado)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Ver',
                                onPressed: () => onView(invoice),
                                icon: const Icon(Icons.visibility_outlined),
                              ),
                              IconButton(
                                tooltip: invoice.isCancelled ? 'Já cancelada' : 'Cancelar',
                                onPressed: invoice.isCancelled ? null : () => onCancel(invoice),
                                icon: const Icon(Icons.block_rounded),
                              ),
                              IconButton(
                                tooltip: 'Impressão (em breve)',
                                onPressed: null,
                                icon: const Icon(Icons.print_outlined),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(growable: false),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
