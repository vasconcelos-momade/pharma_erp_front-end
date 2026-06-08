import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/catalog/pdv_catalog_cache_policy.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<String?> fetchCatalogVersion();
  Future<List<ProductModel>> listCatalogProducts();

  Future<PaginationResponse<ProductModel>> searchProducts({
    String? query,
    String? barcode,
    int page = 1,
    int pageSize = 20,
  });
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  ProductRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<String?> fetchCatalogVersion() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPosProdutosCatalogVersion,
      );
      final data = response.data;
      if (data == null) {
        return null;
      }
      final payload = ApiEnvelope.unwrapMap(data);
      final version = payload['catalogVersion']?.toString().trim();
      if (version != null && version.isNotEmpty) {
        PdvCatalogCachePolicy.setCatalogVersion(version);
      }
      return version;
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  void _applyCatalogMeta(Map<String, dynamic>? json) {
    if (json == null) {
      return;
    }
    final meta = ApiEnvelope.unwrapMeta(json);
    final fromMeta = meta?['catalogVersion']?.toString();
    if (fromMeta != null && fromMeta.isNotEmpty) {
      PdvCatalogCachePolicy.setCatalogVersion(fromMeta);
      return;
    }
    final fromData = json['data'];
    if (fromData is Map<String, dynamic>) {
      final embedded = fromData['catalogVersion']?.toString();
      if (embedded != null && embedded.isNotEmpty) {
        PdvCatalogCachePolicy.setCatalogVersion(embedded);
      }
    }
  }

  @override
  Future<List<ProductModel>> listCatalogProducts() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.tenantProdutos);
      final data = response.data;
      if (data == null) {
        return const <ProductModel>[];
      }

      final items = data is List
          ? data
          : ApiEnvelope.unwrapList(data);

      return items
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<PaginationResponse<ProductModel>> searchProducts({
    String? query,
    String? barcode,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPosProdutosSearch,
        queryParameters: <String, dynamic>{
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (barcode != null && barcode.trim().isNotEmpty) 'barcode': barcode.trim(),
          'page': page,
          'pageSize': pageSize,
        },
      );
      final data = response.data;
      if (data == null) {
        return const PaginationResponse<ProductModel>(items: []);
      }

      _applyCatalogMeta(data);
      final payload = ApiEnvelope.unwrapMap(data);
      final items = (payload['items'] as List<dynamic>? ?? <dynamic>[])
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return PaginationResponse<ProductModel>(
        items: items,
        page: payload['page'] as int? ?? page,
        pageSize: payload['pageSize'] as int? ?? pageSize,
        hasMore: payload['hasMore'] as bool? ?? false,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((ref) {
  return ProductRemoteDataSourceImpl(ref.watch(dioProvider));
});
