import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/security/secure_storage_service.dart';
import '../../../../../platform/files/platform_file_delivery.dart';
import '../../../../../platform/printing/thermal/printer_connection.dart';
import '../../../../../platform/printing/thermal/thermal_printer_service.dart';
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

  Future<void> _openInvoicePdf(String invoiceId) async {
    final document = await ref.read(invoiceRepositoryProvider).getInvoicePdf(
          invoiceId,
        );

    await PlatformFileDelivery.openBytes(
      bytes: document.bytes,
      fileName: document.fileName,
      contentType: document.contentType,
    );
  }

  Future<PrinterConnection?> _readDefaultPrinterConnection() async {
    final raw = await ref.read(secureStorageProvider).readThermalPrinterDefault();
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      return PrinterConnection.fromStorageValue(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> exportPdf({
    required String invoiceId,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      activeInvoiceId: invoiceId,
      lastAction: 'pdf',
      clearError: true,
    );

    try {
      await _openInvoicePdf(invoiceId);

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

  Future<void> printReceipt({
    required String invoiceId,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      activeInvoiceId: invoiceId,
      lastAction: 'print',
      clearError: true,
    );

    try {
      final connection = await _readDefaultPrinterConnection();
      if (connection == null) {
        await _openInvoicePdf(invoiceId);
        state = state.copyWith(
          isSubmitting: false,
          clearActiveInvoice: true,
          clearError: true,
        );
        return;
      }

      final artifact =
          await ref.read(invoiceRepositoryProvider).getInvoicePrintArtifact(
                invoiceId,
              );

      try {
        await ThermalPrinterService.printReceipt(
          bytes: artifact.bytes,
          fileName: artifact.fileName,
          contentType: artifact.contentType,
          connection: connection,
        );
      } catch (_) {
        await _openInvoicePdf(invoiceId);
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

      ref.read(invoiceDetailProvider.notifier).markCancelled(invoiceId: invoiceId);

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
