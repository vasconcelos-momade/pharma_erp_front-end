import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../models/compra_model.dart';
import '../../domain/entities/compra.dart';

abstract class CompraRemoteDataSource {
  Future<List<FornecedorResumoModel>> listarFornecedores({String? search});
  Future<CompraResumoModel> criarCompraPendente(
    CriarCompraPendenteRequestModel request,
  );
  Future<List<CompraResumoModel>> listarCompras({
    required CompraStatus status,
  });
  Future<CompraDetalheModel> obterCompra(String compraId);
  Future<CompraDetalheModel> adicionarItem({
    required String compraId,
    required CompraItemRequestModel request,
  });
  Future<CompraDetalheModel> atualizarItem({
    required String compraId,
    required String itemId,
    required CompraItemRequestModel request,
  });
  Future<CompraDetalheModel> removerItem({
    required String compraId,
    required String itemId,
  });
  Future<CompraReceiptModel> confirmarCompra(String compraId);
}

class CompraRemoteDataSourceImpl implements CompraRemoteDataSource {
  CompraRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<FornecedorResumoModel>> listarFornecedores({String? search}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.tenantFornecedores,
        queryParameters: search == null || search.trim().isEmpty
            ? null
            : <String, dynamic>{'search': search.trim()},
      );
      final payload = _unwrap(response.data);
      if (payload is List) {
        return payload
            .whereType<Map<String, dynamic>>()
            .map(FornecedorResumoModel.fromJson)
            .toList();
      }
      return const <FornecedorResumoModel>[];
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<CompraResumoModel> criarCompraPendente(
    CriarCompraPendenteRequestModel request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantCompras,
        data: request.toJson(),
      );
      return CompraResumoModel.fromJson(_expectMap(response.data, fallback:
          'Resposta inválida ao criar compra pendente.'));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<List<CompraResumoModel>> listarCompras({
    required CompraStatus status,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantCompras,
        queryParameters: <String, dynamic>{'status': status.apiValue},
      );
      final payload = _unwrap(response.data);
      if (payload is List) {
        return payload
            .whereType<Map<String, dynamic>>()
            .map(CompraResumoModel.fromJson)
            .toList();
      }
      if (payload is Map<String, dynamic>) {
        final items = payload['items'];
        if (items is List) {
          return items
              .whereType<Map<String, dynamic>>()
              .map(CompraResumoModel.fromJson)
              .toList();
        }
      }
      return const <CompraResumoModel>[];
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<CompraDetalheModel> obterCompra(String compraId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantCompraDetalhe(compraId),
      );
      return CompraDetalheModel.fromJson(
        _expectMap(response.data, fallback: 'Resposta inválida ao carregar compra.'),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<CompraDetalheModel> adicionarItem({
    required String compraId,
    required CompraItemRequestModel request,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantCompraItens(compraId),
        data: request.toJson(),
      );
      return CompraDetalheModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta inválida ao adicionar item na compra.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<CompraDetalheModel> atualizarItem({
    required String compraId,
    required String itemId,
    required CompraItemRequestModel request,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.tenantCompraItem(compraId, itemId),
        data: request.toJson(),
      );
      return CompraDetalheModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta inválida ao actualizar item da compra.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<CompraDetalheModel> removerItem({
    required String compraId,
    required String itemId,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        ApiConstants.tenantCompraItemRemover(compraId, itemId),
      );
      return CompraDetalheModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta inválida ao remover item da compra.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<CompraReceiptModel> confirmarCompra(String compraId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantCompraConfirmar(compraId),
      );
      return CompraReceiptModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta inválida ao confirmar compra.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  dynamic _unwrap(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    if (data['success'] == true && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  Map<String, dynamic> _expectMap(
    Map<String, dynamic>? data, {
    required String fallback,
  }) {
    final payload = _unwrap(data);
    if (payload is Map<String, dynamic>) {
      return ApiEnvelope.unwrapMap(payload);
    }
    if (payload is Map) {
      return payload.cast<String, dynamic>();
    }
    throw ApiFailure(fallback);
  }
}

final compraRemoteDataSourceProvider = Provider<CompraRemoteDataSource>((ref) {
  return CompraRemoteDataSourceImpl(ref.watch(dioProvider));
});
