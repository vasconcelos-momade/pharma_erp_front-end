import '../../../../../core/contracts/pagination_response.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<String?> fetchCatalogVersion();
  Future<List<Product>> listCatalogProducts();

  Future<PaginationResponse<Product>> searchProducts({
    String? query,
    String? barcode,
    int page = 1,
    int pageSize = 20,
  });

  Future<PaginationResponse<Product>> searchRequisitionProducts({
    String? query,
    int page = 1,
    int pageSize = 20,
  });
}
