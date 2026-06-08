import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/compra.dart';
import '../../domain/repositories/compra_repository.dart';
import '../datasources/compra_remote_datasource.dart';
import '../models/compra_model.dart';

class CompraRepositoryImpl implements CompraRepository {
  CompraRepositoryImpl(this._remoteDataSource);

  final CompraRemoteDataSource _remoteDataSource;

  @override
  Future<List<FornecedorResumo>> listarFornecedores({String? search}) async {
    final response = await _remoteDataSource.listarFornecedores(search: search);
    return response.map((item) => item.toEntity()).toList();
  }

  @override
  Future<CompraResumo> criarCompraPendente(CriarCompraPendenteRequest request) async {
    final response = await _remoteDataSource.criarCompraPendente(
      CriarCompraPendenteRequestModel.fromEntity(request),
    );
    return response.toEntity();
  }

  @override
  Future<List<CompraResumo>> listarCompras({required CompraStatus status}) async {
    final response = await _remoteDataSource.listarCompras(status: status);
    return response.map((item) => item.toEntity()).toList();
  }

  @override
  Future<CompraDetalhe> obterCompra(String compraId) async {
    final response = await _remoteDataSource.obterCompra(compraId);
    return response.toEntity();
  }

  @override
  Future<CompraDetalhe> adicionarItem({
    required String compraId,
    required CompraItemRequest request,
  }) async {
    final response = await _remoteDataSource.adicionarItem(
      compraId: compraId,
      request: CompraItemRequestModel.fromEntity(request),
    );
    return response.toEntity();
  }

  @override
  Future<CompraDetalhe> atualizarItem({
    required String compraId,
    required String itemId,
    required CompraItemRequest request,
  }) async {
    final response = await _remoteDataSource.atualizarItem(
      compraId: compraId,
      itemId: itemId,
      request: CompraItemRequestModel.fromEntity(request),
    );
    return response.toEntity();
  }

  @override
  Future<CompraDetalhe> removerItem({
    required String compraId,
    required String itemId,
  }) async {
    final response = await _remoteDataSource.removerItem(
      compraId: compraId,
      itemId: itemId,
    );
    return response.toEntity();
  }

  @override
  Future<CompraReceipt> confirmarCompra(String compraId) async {
    final response = await _remoteDataSource.confirmarCompra(compraId);
    return response.toEntity();
  }
}

final compraRepositoryProvider = Provider<CompraRepository>((ref) {
  return CompraRepositoryImpl(ref.watch(compraRemoteDataSourceProvider));
});
