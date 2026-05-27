import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/invoice_summary.dart';

class InvoiceDetailState {
  const InvoiceDetailState({
    this.selected,
  });

  final InvoiceSummary? selected;

  bool get hasSelection => selected != null;

  InvoiceDetailState copyWith({
    InvoiceSummary? selected,
    bool clearSelection = false,
  }) {
    return InvoiceDetailState(
      selected: clearSelection ? null : (selected ?? this.selected),
    );
  }
}

class InvoiceDetailController extends Notifier<InvoiceDetailState> {
  @override
  InvoiceDetailState build() => const InvoiceDetailState();

  void open(InvoiceSummary invoice) {
    state = state.copyWith(selected: invoice);
  }

  void close() {
    state = state.copyWith(clearSelection: true);
  }
}

final invoiceDetailProvider =
    NotifierProvider<InvoiceDetailController, InvoiceDetailState>(
  InvoiceDetailController.new,
);
