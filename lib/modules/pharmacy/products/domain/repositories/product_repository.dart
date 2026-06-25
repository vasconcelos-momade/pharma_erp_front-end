import '../../../../../core/contracts/pagination_response.dart';
import '../entities/categoria_produto.dart';
import '../entities/product.dart';
import '../entities/product_tax_rule.dart';

abstract class ProductRepository {
  Future<String?> fetchCatalogVersion();

  Future<Product> getProduct(String id);
  Future<Product> createProduct(Map<String, dynamic> payload);
  Future<Product> updateProduct(String id, Map<String, dynamic> payload);
  Future<void> deleteProduct(String id);
  Future<List<ProductTaxRule>> listTaxRules();

  Future<PaginationResponse<Product>> searchMasterProducts({
    String? query,
    String? barcode,
    CategoriaProduto? categoria,
    bool includeInactive = false,
    int page = 1,
    int pageSize = 20,
  });

  Future<PaginationResponse<Product>> searchProducts({
    String? query,
    String? barcode,
    CategoriaProduto? categoria,
    int page = 1,
    int pageSize = 20,
  });

  Future<PaginationResponse<Product>> searchRequisitionProducts({
    String? query,
    CategoriaProduto? categoria,
    int page = 1,
    int pageSize = 20,
  });
}
