import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../services/invoice_cache_policy.dart';
import 'invoice_detail_provider.dart';
import 'invoice_list_provider.dart';

class InvoiceActionState {
  const InvoiceActionState({
    this.isSubmitting = false,
    this.activeInvoiceId,
    this.errorMessage,
    this.lastAction,
  });

  final bool isSubmitting;
  final String? activeInvoiceId;
  final String? errorMessage;
  final String? lastAction;

  InvoiceActionState copyWith({
    bool? isSubmitting,
    String? activeInvoiceId,
    String? errorMessage,
    String? lastAction,
    bool clearError = false,
    bool clearActiveInvoice = false,
  }) {
    return InvoiceActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      activeInvoiceId: clearActiveInvoice
          ? null
          : (activeInvoiceId ?? this.activeInvoiceId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastAction: lastAction ?? this.lastAction,
    );
  }
}

class InvoiceActionController extends Notifier<InvoiceActionState> {
  @override
  InvoiceActionState build() => const InvoiceActionState();

  Future<void> cancelInvoice({
    required String invoiceId,
    required String motivo,
    String? observacoes,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      activeInvoiceId: invoiceId,
      lastAction: 'cancel',
      clearError: true,
    );

    try {
      await ref.read(invoiceRepositoryProvider).cancelInvoice(
            invoiceId: invoiceId,
            motivo: motivo,
            observacoes: observacoes,
          );
      invalidateInvoiceListCache();
      ref.invalidate(invoiceListProvider);
      // Mantém a lista sincronizada mesmo quando o estado anterior vinha de cache.
      unawaited(ref.read(invoiceListProvider.notifier).refresh());

      final selected = ref.read(invoiceDetailProvider).selected;
      if (selected?.id == invoiceId) {
        ref.read(invoiceDetailProvider.notifier).open(
              selected!.copyWith(
                estado: 'ANULADA',
                cancelledAt: DateTime.now(),
              ),
            );
      }

      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}

final invoiceActionProvider =
    NotifierProvider<InvoiceActionController, InvoiceActionState>(
  InvoiceActionController.new,
);
