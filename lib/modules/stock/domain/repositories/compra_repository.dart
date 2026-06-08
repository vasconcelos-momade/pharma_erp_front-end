import '../entities/compra.dart';

abstract class CompraRepository {
  Future<List<FornecedorResumo>> listarFornecedores({String? search});
  Future<CompraResumo> criarCompraPendente(CriarCompraPendenteRequest request);
  Future<List<CompraResumo>> listarCompras({required CompraStatus status});
  Future<CompraDetalhe> obterCompra(String compraId);
  Future<CompraDetalhe> adicionarItem({
    required String compraId,
    required CompraItemRequest request,
  });
  Future<CompraDetalhe> removerItem({
    required String compraId,
    required String itemId,
  });
  Future<CompraReceipt> confirmarCompra(String compraId);
}
