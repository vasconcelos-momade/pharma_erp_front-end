import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/catalog/pdv_catalog_cache_policy.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../../domain/entities/product_tax_rule.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<String?> fetchCatalogVersion();

  Future<ProductModel> getProduct(String id);
  Future<ProductModel> createProduct(Map<String, dynamic> payload);
  Future<ProductModel> updateProduct(String id, Map<String, dynamic> payload);
  Future<void> deleteProduct(String id);
  Future<List<ProductTaxRule>> listTaxRules();

  Future<PaginationResponse<ProductModel>> searchMasterProducts({
    String? query,
    String? barcode,
    String? categoria,
    bool includeInactive = false,
    int page = 1,
    int pageSize = 20,
  });

  Future<PaginationResponse<ProductModel>> searchProducts({
    String? query,
    String? barcode,
    String? categoria,
    int page = 1,
    int pageSize = 20,
  });

  Future<PaginationResponse<ProductModel>> searchRequisitionProducts({
    String? query,
    String? categoria,
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

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }

  bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) {
      return defaultValue;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
    return defaultValue;
  }

  @override
  Future<ProductModel> getProduct(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantProduto(id),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Produto não encontrado');
      }
      return ProductModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<ProductModel> createProduct(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantProdutos,
        data: payload,
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao criar produto');
      }
      return ProductModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<ProductModel> updateProduct(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiConstants.tenantProduto(id),
        data: payload,
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao actualizar produto');
      }
      return ProductModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _dio.delete<void>(ApiConstants.tenantProduto(id));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<List<ProductTaxRule>> listTaxRules() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.tenantPosTaxRules);
      return ApiEnvelope.unwrapList(response.data)
          .map((json) => ProductTaxRule(
                id: json['id']?.toString(),
                tipo: json['tipo'] as String? ?? 'IVA_NORMAL',
                taxa: _toDouble(json['taxa']),
                codigo: json['codigo'] as String?,
                nome: json['nome'] as String?,
                descricao: json['descricao'] as String?,
                ativo: _toBool(json['ativo'], defaultValue: true),
              ))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<PaginationResponse<ProductModel>> searchMasterProducts({
    String? query,
    String? barcode,
    String? categoria,
    bool includeInactive = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantProdutos,
        queryParameters: <String, dynamic>{
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (barcode != null && barcode.trim().isNotEmpty) 'barcode': barcode.trim(),
          if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
          if (includeInactive) 'includeInactive': true,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final data = response.data;
      if (data == null) {
        return const PaginationResponse<ProductModel>(items: []);
      }

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

  @override
  Future<PaginationResponse<ProductModel>> searchProducts({
    String? query,
    String? barcode,
    String? categoria,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPosProdutosSearch,
        queryParameters: <String, dynamic>{
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (barcode != null && barcode.trim().isNotEmpty) 'barcode': barcode.trim(),
          if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
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

  @override
  Future<PaginationResponse<ProductModel>> searchRequisitionProducts({
    String? query,
    String? categoria,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantRequisicoesProdutosSearch,
        queryParameters: <String, dynamic>{
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final data = response.data;
      if (data == null) {
        return const PaginationResponse<ProductModel>(items: []);
      }

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
