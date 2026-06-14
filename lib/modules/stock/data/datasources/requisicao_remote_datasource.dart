import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../../domain/entities/requisicao.dart';
import '../models/fornecedor_model.dart';
import '../models/requisicao_model.dart';

abstract class RequisicaoRemoteDataSource {
  Future<List<FornecedorResumoModel>> listarFornecedores({String? search});
  Future<RequisicaoOperacaoResultadoModel> criarRequisicao(
    CriarRequisicaoRequestModel request,
  );
  Future<CriarLoteResultModel> criarLote(CriarLoteRequestModel request);
  Future<List<RequisicaoResumoModel>> listarRequisicoes({
    RequisicaoStatus? status,
    RequisicaoTipo? tipo,
  });
  Future<RequisicaoDetalheModel> obterRequisicao(String requisicaoId);
  Future<RequisicaoDetalheModel> atualizarRequisicao({
    required String requisicaoId,
    required AtualizarRequisicaoRequestModel request,
  });
  Future<RequisicaoDetalheModel> adicionarItem({
    required String requisicaoId,
    required RequisicaoItemRequestModel request,
  });
  Future<RequisicaoDetalheModel> atualizarItem({
    required String requisicaoId,
    required String itemId,
    required RequisicaoItemRequestModel request,
  });
  Future<RequisicaoDetalheModel> removerItem({
    required String requisicaoId,
    required String itemId,
  });
  Future<List<ProdutoLoteDisponivelModel>> listarLotesProduto(String produtoId);
  Future<RequisicaoOperacaoResultadoModel> aprovarRequisicao(
    String requisicaoId,
  );
  Future<RequisicaoOperacaoResultadoModel> rejeitarRequisicao(
    String requisicaoId,
  );
  Future<RequisicaoOperacaoResultadoModel> cancelarRequisicao(
    String requisicaoId,
  );
}

class RequisicaoRemoteDataSourceImpl implements RequisicaoRemoteDataSource {
  RequisicaoRemoteDataSourceImpl(this._dio);

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
  Future<RequisicaoOperacaoResultadoModel> criarRequisicao(
    CriarRequisicaoRequestModel request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantRequisicoes,
        data: request.toJson(),
      );
      return RequisicaoOperacaoResultadoModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta invalida ao criar requisicao.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<CriarLoteResultModel> criarLote(
    CriarLoteRequestModel request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantLotes,
        data: request.toJson(),
      );
      return CriarLoteResultModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta invalida ao criar lote.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<List<RequisicaoResumoModel>> listarRequisicoes({
    RequisicaoStatus? status,
    RequisicaoTipo? tipo,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantRequisicoes,
        queryParameters: <String, dynamic>{
          if (status != null) 'status': status.apiValue,
          if (tipo != null) 'tipo': tipo.apiValue,
        },
      );
      final payload = _unwrap(response.data);
      if (payload is List) {
        return payload
            .whereType<Map<String, dynamic>>()
            .map(RequisicaoResumoModel.fromJson)
            .toList();
      }
      return const <RequisicaoResumoModel>[];
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<RequisicaoDetalheModel> obterRequisicao(
    String requisicaoId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantRequisicaoDetalhe(requisicaoId),
      );
      return RequisicaoDetalheModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta invalida ao carregar requisicao.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<RequisicaoDetalheModel> atualizarRequisicao({
    required String requisicaoId,
    required AtualizarRequisicaoRequestModel request,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        ApiConstants.tenantRequisicaoDetalhe(requisicaoId),
        data: request.toJson(),
      );
      return obterRequisicao(requisicaoId);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<RequisicaoDetalheModel> adicionarItem({
    required String requisicaoId,
    required RequisicaoItemRequestModel request,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantRequisicaoItens(requisicaoId),
        data: request.toJson(),
      );
      return obterRequisicao(requisicaoId);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<RequisicaoDetalheModel> atualizarItem({
    required String requisicaoId,
    required String itemId,
    required RequisicaoItemRequestModel request,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        ApiConstants.tenantRequisicaoItem(requisicaoId, itemId),
        data: request.toJson(),
      );
      return obterRequisicao(requisicaoId);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<RequisicaoDetalheModel> removerItem({
    required String requisicaoId,
    required String itemId,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiConstants.tenantRequisicaoItem(requisicaoId, itemId),
      );
      return obterRequisicao(requisicaoId);
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
  Future<RequisicaoOperacaoResultadoModel> aprovarRequisicao(
    String requisicaoId,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantRequisicaoAprovar(requisicaoId),
      );
      return RequisicaoOperacaoResultadoModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta invalida ao aprovar requisicao.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<RequisicaoOperacaoResultadoModel> rejeitarRequisicao(
    String requisicaoId,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantRequisicaoRejeitar(requisicaoId),
      );
      return RequisicaoOperacaoResultadoModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta invalida ao rejeitar requisicao.',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<RequisicaoOperacaoResultadoModel> cancelarRequisicao(
    String requisicaoId,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantRequisicaoCancelar(requisicaoId),
      );
      return RequisicaoOperacaoResultadoModel.fromJson(
        _expectMap(
          response.data,
          fallback: 'Resposta invalida ao cancelar requisicao.',
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

final requisicaoRemoteDataSourceProvider =
    Provider<RequisicaoRemoteDataSource>((ref) {
  return RequisicaoRemoteDataSourceImpl(ref.watch(dioProvider));
});
