import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/utils/list_csv_exporter.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../domain/entities/invoice_summary.dart';
import '../providers/invoice_action_provider.dart';
import '../providers/invoice_detail_provider.dart';
import '../providers/invoice_list_provider.dart';
import '../widgets/cancel_invoice_dialog.dart';
import '../widgets/invoice_detail_screen.dart';
import '../widgets/invoices_body.dart';

class SalesInvoicesPage extends ConsumerStatefulWidget {
  const SalesInvoicesPage({super.key});

  @override
  ConsumerState<SalesInvoicesPage> createState() => _SalesInvoicesPageState();
}

class _SalesInvoicesPageState extends ConsumerState<SalesInvoicesPage> {
  late final TextEditingController _searchController;
  static final _currency = NumberFormat('#,##0.00', 'pt_MZ');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    final initial = ref.read(invoiceListProvider).query.search;
    _searchController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<InvoiceActionState>(invoiceActionProvider, (previous, next) {
      if (!mounted || previous == next) {
        return;
      }
      final previousSubmitting = previous?.isSubmitting ?? false;
      if (previousSubmitting &&
          !next.isSubmitting &&
          next.errorMessage == null) {
        PharmaFeedback.success(context, 'Fatura cancelada com sucesso.');
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        PharmaFeedback.error(context, next.errorMessage!);
      }
    });

    final listState = ref.watch(invoiceListProvider);
    final detailState = ref.watch(invoiceDetailProvider);
    final query = listState.query;

    if (_searchController.text != query.search) {
      _searchController.value = TextEditingValue(
        text: query.search,
        selection: TextSelection.collapsed(offset: query.search.length),
      );
    }

    return EnterpriseModuleHub(
      title: 'Faturas de venda',
      subtitle:
          'Histórico operacional do POS com pesquisa, filtros rápidos, cache em memória e cancelamento seguro.',
      tag: 'Terminal',
      actions: [
        OutlinedButton.icon(
          onPressed: listState.items.isEmpty
              ? null
              : () => _exportInvoices(listState),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Exportar CSV'),
        ),
        OutlinedButton.icon(
          onPressed: listState.isBusy
              ? null
              : () => ref.read(invoiceListProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      child: InvoicesBody(
        searchController: _searchController,
        listState: listState,
        detailState: detailState,
        onView: _openDetails,
        onCancel: _confirmCancelInvoice,
      ),
    );
  }

  Future<void> _openDetails(InvoiceSummary invoice) async {
    ref.read(invoiceDetailProvider.notifier).open(invoice);
    final isMobile = PharmaScreenLayout.isMobile(context);

    if (isMobile) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (screenContext) => InvoiceDetailScreen(
            invoice: invoice,
            onCancel: invoice.isCancelled
                ? null
                : () {
                    Navigator.of(screenContext).pop();
                    _confirmCancelInvoice(invoice);
                  },
          ),
        ),
      );
      ref.read(invoiceDetailProvider.notifier).close();
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final t = context.pharmaTokens;
        final s = context.spacing;
        return Dialog(
          alignment: Alignment.centerRight,
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: s.md),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 520,
            decoration: BoxDecoration(
              color: t.bgPrimary,
              borderRadius: BorderRadius.circular(t.radiusXl),
              border: Border.all(color: t.border.withValues(alpha: 0.55)),
            ),
            child: InvoiceDetailPanel(
              invoice: invoice,
              onClose: () => Navigator.of(dialogContext).pop(),
              onCancel: invoice.isCancelled
                  ? null
                  : () {
                      Navigator.of(dialogContext).pop();
                      _confirmCancelInvoice(invoice);
                    },
            ),
          ),
        );
      },
    );
    ref.read(invoiceDetailProvider.notifier).close();
  }

  Future<void> _confirmCancelInvoice(InvoiceSummary invoice) async {
    if (invoice.isCancelled) {
      return;
    }

    final result = await showDialog<CancelInvoicePayload>(
      context: context,
      builder: (dialogContext) => CancelInvoiceDialog(invoice: invoice),
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      await ref
          .read(invoiceActionProvider.notifier)
          .cancelInvoice(
            invoiceId: invoice.id,
            motivo: result.motivo,
            observacoes: result.observacoes,
          );
    } catch (_) {
      // A mensagem ja e tratada pelo listener do provider.
    }
  }

  Future<void> _exportInvoices(InvoiceListState listState) async {
    await ListCsvExporter.export(
      fileName: 'faturas-pagina-${listState.query.page}',
      headers: const [
        'Fatura',
        'Cliente',
        'Terminal',
        'Total',
        'Estado',
        'Data',
      ],
      rows: listState.items
          .map(
            (inv) => [
              inv.numero,
              inv.cliente?.nome ?? '—',
              inv.terminal?.codigo ?? inv.terminal?.nome ?? '—',
              _currency.format(inv.total),
              inv.estado,
              _dateTime.format(inv.createdAt),
            ],
          )
          .toList(),
    );
  }
}
