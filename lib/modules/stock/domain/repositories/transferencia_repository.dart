import '../entities/transferencia.dart';

abstract class TransferenciaRepository {
  Future<TransferenciaOperacaoResultado> criarTransferencia(
    CriarTransferenciaRequest request,
  );

  Future<List<TransferenciaResumo>> listarTransferencias({
    required TransferenciaStatus status,
  });

  Future<TransferenciaDetalhe> obterTransferencia(String transferenciaId);

  Future<TransferenciaDetalhe> adicionarItem({
    required String transferenciaId,
    required TransferenciaItemRequest request,
  });

  Future<TransferenciaDetalhe> removerItem({
    required String transferenciaId,
    required String itemId,
  });

  Future<List<ProdutoLoteDisponivel>> listarLotesProduto(String produtoId);

  Future<TransferenciaOperacaoResultado> confirmarTransferencia(
    String transferenciaId,
  );

  Future<TransferenciaOperacaoResultado> cancelarTransferencia(
    String transferenciaId,
  );
}
