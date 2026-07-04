import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/fornecedor.dart';
import '../../domain/entities/requisicao.dart';
import '../../domain/repositories/requisicao_repository.dart';
import '../datasources/requisicao_remote_datasource.dart';
import '../models/requisicao_model.dart';

class RequisicaoRepositoryImpl implements RequisicaoRepository {
  RequisicaoRepositoryImpl(this._remoteDataSource);

  final RequisicaoRemoteDataSource _remoteDataSource;

  @override
  Future<List<FornecedorResumo>> listarFornecedores({String? search}) async {
    final response = await _remoteDataSource.listarFornecedores(search: search);
    return response.map((item) => item.toEntity()).toList();
  }

  @override
  Future<RequisicaoOperacaoResultado> criarRequisicao(
    CriarRequisicaoRequest request,
  ) async {
    final response = await _remoteDataSource.criarRequisicao(
      CriarRequisicaoRequestModel.fromEntity(request),
    );
    return response.toEntity();
  }

  @override
  Future<CriarLoteResult> criarLote(CriarLoteRequest request) async {
    final response = await _remoteDataSource.criarLote(
      CriarLoteRequestModel.fromEntity(request),
    );
    return response.toEntity();
  }

  @override
  Future<List<RequisicaoResumo>> listarRequisicoes({
    RequisicaoStatus? status,
    RequisicaoTipo? tipo,
  }) async {
    final response = await _remoteDataSource.listarRequisicoes(
      status: status,
      tipo: tipo,
    );
    return response.map((item) => item.toEntity()).toList();
  }

  @override
  Future<RequisicaoDetalhe> obterRequisicao(String requisicaoId) async {
    final response = await _remoteDataSource.obterRequisicao(requisicaoId);
    return response.toEntity();
  }

  @override
  Future<RequisicaoDetalhe> atualizarRequisicao({
    required String requisicaoId,
    required AtualizarRequisicaoRequest request,
  }) async {
    final response = await _remoteDataSource.atualizarRequisicao(
      requisicaoId: requisicaoId,
      request: AtualizarRequisicaoRequestModel.fromEntity(request),
    );
    return response.toEntity();
  }

  @override
  Future<RequisicaoDetalhe> adicionarItem({
    required String requisicaoId,
    required RequisicaoItemRequest request,
  }) async {
    final response = await _remoteDataSource.adicionarItem(
      requisicaoId: requisicaoId,
      request: RequisicaoItemRequestModel.fromEntity(request),
    );
    return response.toEntity();
  }

  @override
  Future<RequisicaoDetalhe> atualizarItem({
    required String requisicaoId,
    required String itemId,
    required RequisicaoItemRequest request,
  }) async {
    final response = await _remoteDataSource.atualizarItem(
      requisicaoId: requisicaoId,
      itemId: itemId,
      request: RequisicaoItemRequestModel.fromEntity(request),
    );
    return response.toEntity();
  }

  @override
  Future<RequisicaoDetalhe> removerItem({
    required String requisicaoId,
    required String itemId,
  }) async {
    final response = await _remoteDataSource.removerItem(
      requisicaoId: requisicaoId,
      itemId: itemId,
    );
    return response.toEntity();
  }

  @override
  Future<List<ProdutoLoteDisponivel>> listarLotesProduto(
    String produtoId,
  ) async {
    final response = await _remoteDataSource.listarLotesProduto(produtoId);
    return response
        .map(
          (lote) => ProdutoLoteDisponivel(
            id: lote.id,
            numeroLote: lote.numeroLote,
            dataValidade: lote.dataValidade,
            quantidadeDisponivel: lote.quantidadeDisponivel,
          ),
        )
        .toList();
  }

  @override
  Future<RequisicaoOperacaoResultado> aprovarRequisicao(
    String requisicaoId,
  ) async {
    final response = await _remoteDataSource.aprovarRequisicao(requisicaoId);
    return response.toEntity();
  }

  @override
  Future<RequisicaoOperacaoResultado> rejeitarRequisicao(
    String requisicaoId,
  ) async {
    final response = await _remoteDataSource.rejeitarRequisicao(requisicaoId);
    return response.toEntity();
  }

  @override
  Future<RequisicaoOperacaoResultado> cancelarRequisicao(
    String requisicaoId,
  ) async {
    final response = await _remoteDataSource.cancelarRequisicao(requisicaoId);
    return response.toEntity();
  }
}

final requisicaoRepositoryProvider = Provider<RequisicaoRepository>((ref) {
  return RequisicaoRepositoryImpl(
    ref.watch(requisicaoRemoteDataSourceProvider),
  );
});
