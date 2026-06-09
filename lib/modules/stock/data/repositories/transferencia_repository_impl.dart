import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transferencia.dart';
import '../../domain/repositories/transferencia_repository.dart';
import '../datasources/transferencia_remote_datasource.dart';
import '../models/transferencia_model.dart';

class TransferenciaRepositoryImpl implements TransferenciaRepository {
  TransferenciaRepositoryImpl(this._remoteDataSource);

  final TransferenciaRemoteDataSource _remoteDataSource;

  @override
  Future<TransferenciaOperacaoResultado> criarTransferencia(
    CriarTransferenciaRequest request,
  ) async {
    final response = await _remoteDataSource.criarTransferencia(
      CriarTransferenciaRequestModel.fromEntity(request),
    );
    return response.toEntity();
  }

  @override
  Future<List<TransferenciaResumo>> listarTransferencias({
    required TransferenciaStatus status,
  }) async {
    final response = await _remoteDataSource.listarTransferencias(status: status);
    return response.map((item) => item.toEntity()).toList();
  }

  @override
  Future<TransferenciaDetalhe> obterTransferencia(String transferenciaId) async {
    final response = await _remoteDataSource.obterTransferencia(transferenciaId);
    return response.toEntity();
  }

  @override
  Future<TransferenciaDetalhe> adicionarItem({
    required String transferenciaId,
    required TransferenciaItemRequest request,
  }) async {
    final response = await _remoteDataSource.adicionarItem(
      transferenciaId: transferenciaId,
      request: TransferenciaItemRequestModel.fromEntity(request),
    );
    return response.toEntity();
  }

  @override
  Future<TransferenciaDetalhe> removerItem({
    required String transferenciaId,
    required String itemId,
  }) async {
    final response = await _remoteDataSource.removerItem(
      transferenciaId: transferenciaId,
      itemId: itemId,
    );
    return response.toEntity();
  }

  @override
  Future<List<ProdutoLoteDisponivel>> listarLotesProduto(String produtoId) async {
    final response = await _remoteDataSource.listarLotesProduto(produtoId);
    return response
        .map(
          (lote) => ProdutoLoteDisponivel(
            id: lote.id,
            numeroLote: lote.numeroLote,
            dataValidade: lote.dataValidade,
            quantidadeAtual: lote.quantidadeAtual,
          ),
        )
        .toList();
  }

  @override
  Future<TransferenciaOperacaoResultado> confirmarTransferencia(
    String transferenciaId,
  ) async {
    final response =
        await _remoteDataSource.confirmarTransferencia(transferenciaId);
    return response.toEntity();
  }

  @override
  Future<TransferenciaOperacaoResultado> cancelarTransferencia(
    String transferenciaId,
  ) async {
    final response =
        await _remoteDataSource.cancelarTransferencia(transferenciaId);
    return response.toEntity();
  }
}

final transferenciaRepositoryProvider = Provider<TransferenciaRepository>((ref) {
  return TransferenciaRepositoryImpl(
    ref.watch(transferenciaRemoteDataSourceProvider),
  );
});
