import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../../domain/entities/transferencia.dart';
import '../models/transferencia_model.dart';

abstract class TransferenciaRemoteDataSource {
  Future<TransferenciaOperacaoResultadoModel> criarTransferencia(
    CriarTransferenciaRequestModel request,
  );
  Future<List<TransferenciaResumoModel>> listarTransferencias({
    required TransferenciaStatus status,
  });
  Future<TransferenciaDetalheModel> obterTransferencia(String transferenciaId);
  Future<TransferenciaDetalheModel> adicionarItem({
    required String transferenciaId,
    required TransferenciaItemRequestModel request,
  });
  Future<TransferenciaDetalheModel> removerItem({
    required String transferenciaId,
    required String itemId,
  });
  Future<List<ProdutoLoteDisponivelModel>> listarLotesProduto(String produtoId);
  Future<TransferenciaOperacaoResultadoModel> confirmarTransferencia(
    String transferenciaId,
  );
  Future<TransferenciaOperacaoResultadoModel> cancelarTransferencia(
    String transferenciaId,
  );
}

class TransferenciaRemoteDataSourceImpl implements TransferenciaRemoteDataSource {
  TransferenciaRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<TransferenciaOperacaoResultadoModel> criarTransferencia(
    CriarTransferenciaRequestModel request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantTransferencias,
        data: request.toJson(),
      );
      return TransferenciaOperacaoResultadoModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta inválida ao criar transferência.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<List<TransferenciaResumoModel>> listarTransferencias({
    required TransferenciaStatus status,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantTransferencias,
        queryParameters: <String, dynamic>{'status': status.apiValue},
      );
      final payload = _unwrap(response.data);
      if (payload is List) {
        return payload
            .whereType<Map<String, dynamic>>()
            .map(TransferenciaResumoModel.fromJson)
            .toList();
      }
      return const <TransferenciaResumoModel>[];
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<TransferenciaDetalheModel> obterTransferencia(
    String transferenciaId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantTransferenciaDetalhe(transferenciaId),
      );
      return TransferenciaDetalheModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta inválida ao carregar transferência.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<TransferenciaDetalheModel> adicionarItem({
    required String transferenciaId,
    required TransferenciaItemRequestModel request,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantTransferenciaItens(transferenciaId),
        data: request.toJson(),
      );
      return obterTransferencia(transferenciaId);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<TransferenciaDetalheModel> removerItem({
    required String transferenciaId,
    required String itemId,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiConstants.tenantTransferenciaItem(transferenciaId, itemId),
      );
      return obterTransferencia(transferenciaId);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<List<ProdutoLoteDisponivelModel>> listarLotesProduto(
    String produtoId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantProdutoLotes(produtoId),
      );
      final payload = _unwrap(response.data);
      if (payload is List) {
        return payload
            .whereType<Map<String, dynamic>>()
            .map(ProdutoLoteDisponivelModel.fromJson)
            .toList();
      }
      return const <ProdutoLoteDisponivelModel>[];
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<TransferenciaOperacaoResultadoModel> confirmarTransferencia(
    String transferenciaId,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantTransferenciaConfirmar(transferenciaId),
      );
      return TransferenciaOperacaoResultadoModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta inválida ao confirmar transferência.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<TransferenciaOperacaoResultadoModel> cancelarTransferencia(
    String transferenciaId,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantTransferenciaCancelar(transferenciaId),
      );
      return TransferenciaOperacaoResultadoModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta inválida ao cancelar transferência.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  dynamic _unwrap(Map<String, dynamic>? data) {
    if (data == null) return null;
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

final transferenciaRemoteDataSourceProvider =
    Provider<TransferenciaRemoteDataSource>((ref) {
  return TransferenciaRemoteDataSourceImpl(ref.watch(dioProvider));
});
