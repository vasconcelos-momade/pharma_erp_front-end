import '../entities/quotation.dart';
import '../entities/quotation_cart_line.dart';

abstract class QuotationRepository {
  Future<QuotationCreateResult> createQuotation({
    required String clienteId,
    required DateTime validade,
    String? observacoes,
    required List<QuotationCartLine> lines,
  });
}
