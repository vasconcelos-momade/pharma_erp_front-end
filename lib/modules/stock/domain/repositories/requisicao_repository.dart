import '../entities/fornecedor.dart';
import '../entities/requisicao.dart';

abstract class RequisicaoRepository {
  Future<List<FornecedorResumo>> listarFornecedores({String? search});
  Future<RequisicaoOperacaoResultado> criarRequisicao(
    CriarRequisicaoRequest request,
  );

  Future<CriarLoteResult> criarLote(CriarLoteRequest request);

  Future<List<RequisicaoResumo>> listarRequisicoes({
    RequisicaoStatus? status,
    RequisicaoTipo? tipo,
  });

  Future<RequisicaoDetalhe> obterRequisicao(String requisicaoId);

  Future<RequisicaoDetalhe> atualizarRequisicao({
    required String requisicaoId,
    required AtualizarRequisicaoRequest request,
  });

  Future<RequisicaoDetalhe> adicionarItem({
    required String requisicaoId,
    required RequisicaoItemRequest request,
  });

  Future<RequisicaoDetalhe> atualizarItem({
    required String requisicaoId,
    required String itemId,
    required RequisicaoItemRequest request,
  });

  Future<RequisicaoDetalhe> removerItem({
    required String requisicaoId,
    required String itemId,
  });

  Future<List<ProdutoLoteDisponivel>> listarLotesProduto(String produtoId);

  Future<RequisicaoOperacaoResultado> aprovarRequisicao(String requisicaoId);

  Future<RequisicaoOperacaoResultado> rejeitarRequisicao(String requisicaoId);

  Future<RequisicaoOperacaoResultado> cancelarRequisicao(String requisicaoId);
}
