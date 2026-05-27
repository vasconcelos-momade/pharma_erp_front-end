import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remoteDataSource);

  final ProductRemoteDataSource _remoteDataSource;

  @override
  Future<String?> fetchCatalogVersion() => _remoteDataSource.fetchCatalogVersion();

  @override
  Future<PaginationResponse<Product>> searchProducts({
    String? query,
    String? barcode,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _remoteDataSource.searchProducts(
      query: query,
      barcode: barcode,
      page: page,
      pageSize: pageSize,
    );
    return PaginationResponse<Product>(
      items: response.items.map(_toEntity).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
    );
  }

  Product _toEntity(ProductModel model) {
    return Product(
      id: model.id,
      nome: model.nome,
      substanciaActiva: model.substanciaActiva,
      dosagem: model.dosagem,
      forma: model.forma,
      apresentacao: model.apresentacao,
      ativo: model.ativo,
      barcode: model.barcode,
      tipoDispensacao: model.tipoDispensacao,
      requiresPrescription: model.requiresPrescription,
      requiresDoubleCheck: model.requiresDoubleCheck,
      requiresPsychotropicBook: model.requiresPsychotropicBook,
      precoVenda: model.precoVenda,
      estoqueAtual: model.estoqueAtual,
      estoqueMinimo: model.estoqueMinimo,
      lote: model.lote,
      dataValidade: model.dataValidade,
      createdAt: model.createdAt,
      taxRule: model.taxRule,
    );
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(productRemoteDataSourceProvider));
});
