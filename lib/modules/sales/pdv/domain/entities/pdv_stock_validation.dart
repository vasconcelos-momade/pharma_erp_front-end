class PdvStockValidation {
  const PdvStockValidation({
    required this.permitido,
    required this.estoqueDisponivel,
    required this.quantidadeDisponivel,
    required this.mensagem,
  });

  final bool permitido;
  final bool estoqueDisponivel;
  final int quantidadeDisponivel;
  final String mensagem;
}
