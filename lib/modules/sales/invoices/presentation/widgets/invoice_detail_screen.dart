import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../domain/entities/invoice_summary.dart';
import '../providers/invoice_action_provider.dart';
import 'invoice_detail_widgets.dart';
import 'invoice_formatters.dart';
import 'invoice_status_badge.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({
    super.key,
    required this.invoice,
    this.onCancel,
  });

  final InvoiceSummary invoice;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final actionState = ref.watch(invoiceActionProvider);
    final isCancelling =
        actionState.isSubmitting && actionState.activeInvoiceId == invoice.id;

    return Scaffold(
      backgroundColor: t.bgPrimary,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(invoice.numero),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(s.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.cliente?.nome ?? 'Consumidor final',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: t.textMuted,
                            ),
                      ),
                      SizedBox(height: s.md),
                      InvoiceStatusBadge(status: invoice.estado),
                      SizedBox(height: s.lg),
                      DetailSection(
                        title: 'Dados da fatura',
                        children: [
                          DetailRow(label: 'Número', value: invoice.numero),
                          DetailRow(label: 'Série', value: invoice.serie ?? '-'),
                          DetailRow(label: 'Data', value: formatDateTime(invoice.createdAt)),
                          DetailRow(
                            label: 'Cancelada em',
                            value: formatDateTime(invoice.cancelledAt),
                          ),
                          DetailRow(
                            label: 'Método de pagamento',
                            value: invoice.tipoPagamento ?? '-',
                          ),
                          DetailRow(
                            label: 'Terminal',
                            value: invoice.terminal?.codigo ?? invoice.terminal?.nome ?? '-',
                          ),
                          DetailRow(
                            label: 'Operador',
                            value: invoice.user?.name ?? '-',
                          ),
                        ],
                      ),
                      SizedBox(height: s.lg),
                      DetailSection(
                        title: 'Totais',
                        children: [
                          DetailRow(label: 'Subtotal', value: formatMoney(invoice.subtotal)),
                          DetailRow(label: 'IVA', value: formatMoney(invoice.ivaTotal)),
                          DetailRow(label: 'Total', value: formatMoney(invoice.total)),
                        ],
                      ),
                      SizedBox(height: s.lg),
                      DetailSection(
                        title: 'Itens e pagamentos',
                        children: [
                          DetailRow(label: 'Linhas registadas', value: '${invoice.itemCount}'),
                          DetailRow(label: 'Pagamentos', value: '${invoice.paymentCount}'),
                          const DetailHint(
                            text:
                                'Detalhe completo, lotes FEFO, PDF e reimpressão ficam preparados no layout e dependem do endpoint de detalhe/impressão.',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: s.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Reimprimir'),
                  ),
                  SizedBox(height: s.sm),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Exportar PDF'),
                  ),
                  SizedBox(height: s.sm),
                  FilledButton.icon(
                    onPressed: isCancelling ? null : onCancel,
                    icon: isCancelling
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.block_rounded),
                    label: const Text('Cancelar fatura'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvoiceDetailPanel extends ConsumerWidget {
  const InvoiceDetailPanel({
    super.key,
    required this.invoice,
    required this.onClose,
    this.onCancel,
  });

  final InvoiceSummary invoice;
  final VoidCallback onClose;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isMobile = PharmaScreenLayout.isMobile(context);
    final actionState = ref.watch(invoiceActionProvider);
    final isCancelling =
        actionState.isSubmitting && actionState.activeInvoiceId == invoice.id;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(s.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    SizedBox(height: s.md),
                    InvoiceStatusBadge(status: invoice.estado),
                    SizedBox(height: s.lg),
                    DetailSection(
                      title: 'Dados da fatura',
                      children: [
                        DetailRow(label: 'Número', value: invoice.numero),
                        DetailRow(label: 'Série', value: invoice.serie ?? '-'),
                        DetailRow(label: 'Data', value: formatDateTime(invoice.createdAt)),
                        DetailRow(
                          label: 'Cancelada em',
                          value: formatDateTime(invoice.cancelledAt),
                        ),
                        DetailRow(
                          label: 'Método de pagamento',
                          value: invoice.tipoPagamento ?? '-',
                        ),
                        DetailRow(
                          label: 'Terminal',
                          value: invoice.terminal?.codigo ?? invoice.terminal?.nome ?? '-',
                        ),
                        DetailRow(
                          label: 'Operador',
                          value: invoice.user?.name ?? '-',
                        ),
                      ],
                    ),
                    SizedBox(height: s.lg),
                    DetailSection(
                      title: 'Totais',
                      children: [
                        DetailRow(label: 'Subtotal', value: formatMoney(invoice.subtotal)),
                        DetailRow(label: 'IVA', value: formatMoney(invoice.ivaTotal)),
                        DetailRow(label: 'Total', value: formatMoney(invoice.total)),
                      ],
                    ),
                    SizedBox(height: s.lg),
                    DetailSection(
                      title: 'Itens e pagamentos',
                      children: [
                        DetailRow(label: 'Linhas registadas', value: '${invoice.itemCount}'),
                        DetailRow(label: 'Pagamentos', value: '${invoice.paymentCount}'),
                        const DetailHint(
                          text:
                              'Detalhe completo, lotes FEFO, PDF e reimpressão ficam preparados no layout e dependem do endpoint de detalhe/impressão.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: s.lg),
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Reimprimir'),
                  ),
                  SizedBox(height: s.sm),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Exportar PDF'),
                  ),
                  SizedBox(height: s.sm),
                  FilledButton.icon(
                    onPressed: isCancelling ? null : onCancel,
                    icon: isCancelling
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.block_rounded),
                    label: const Text('Cancelar fatura'),
                  ),
                ],
              )
            else
              Wrap(
                spacing: s.sm,
                runSpacing: s.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Reimprimir'),
                  ),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Exportar PDF'),
                  ),
                  FilledButton.icon(
                    onPressed: isCancelling ? null : onCancel,
                    icon: isCancelling
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.block_rounded),
                    label: const Text('Cancelar fatura'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
