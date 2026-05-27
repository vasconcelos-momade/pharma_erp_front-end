import '../../../../../core/contracts/pagination_response.dart';
import '../entities/invoice_summary.dart';

abstract class InvoiceRepository {
  Future<PaginationResponse<InvoiceSummary>> listInvoices(InvoiceQuery query);

  Future<void> cancelInvoice({
    required String invoiceId,
    required String motivo,
    String? observacoes,
  });
}
