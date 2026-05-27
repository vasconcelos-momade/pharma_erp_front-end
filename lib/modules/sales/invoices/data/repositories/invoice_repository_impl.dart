import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../domain/entities/invoice_summary.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_remote_datasource.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  InvoiceRepositoryImpl(this._remoteDataSource);

  final InvoiceRemoteDataSource _remoteDataSource;

  @override
  Future<PaginationResponse<InvoiceSummary>> listInvoices(
    InvoiceQuery query,
  ) async {
    final response = await _remoteDataSource.listInvoices(query);
    return PaginationResponse<InvoiceSummary>(
      items: response.items.map((item) => item.toEntity()).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
    );
  }

  @override
  Future<void> cancelInvoice({
    required String invoiceId,
    required String motivo,
    String? observacoes,
  }) {
    return _remoteDataSource.cancelInvoice(
      invoiceId: invoiceId,
      motivo: motivo,
      observacoes: observacoes,
    );
  }
}

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepositoryImpl(ref.watch(invoiceRemoteDataSourceProvider));
});
