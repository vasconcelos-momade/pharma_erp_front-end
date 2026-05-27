import '../../../../../core/contracts/pagination_response.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<String?> fetchCatalogVersion();

  Future<PaginationResponse<Product>> searchProducts({
    String? query,
    String? barcode,
    int page = 1,
    int pageSize = 20,
  });
}
