class EstoqueItem {
  const EstoqueItem({
    required this.id,
    required this.produtoId,
    this.produtoNomeComercial,
    this.produtoNomeGenerico,
    this.produtoBarcode,
    this.categoriaId,
    this.categoriaNome,
    this.fornecedorId,
    this.fornecedorNome,
    required this.numeroLote,
    this.dataValidade,
    this.diasRestantes,
    this.indicadorValidade,
    this.indicadorStock,
    this.quantidadeDisponivel = 0,
    this.quantidadeTotal = 0,
    this.quantidadeInicial = 0,
    this.quantidadeQuarentena = 0,
    this.precoCompra = 0,
    this.precoVenda,
    this.estadoSanitario,
    this.disponibilidade,
    this.ultimaAtualizacao,
    this.estoqueMinimo = 0,
  });

  final String id;
  final String produtoId;
  final String? produtoNomeComercial;
  final String? produtoNomeGenerico;
  final String? produtoBarcode;
  final String? categoriaId;
  final String? categoriaNome;
  final String? fornecedorId;
  final String? fornecedorNome;
  final String numeroLote;
  final DateTime? dataValidade;
  final int? diasRestantes;
  final String? indicadorValidade;
  final String? indicadorStock;
  final num quantidadeDisponivel;
  final num quantidadeTotal;
  final num quantidadeInicial;
  final num quantidadeQuarentena;
  final num precoCompra;
  final num? precoVenda;
  final String? estadoSanitario;
  final String? disponibilidade;
  final DateTime? ultimaAtualizacao;
  final num estoqueMinimo;

  Map<String, dynamic> toActionMap() => <String, dynamic>{
        'id': id,
        'produtoId': produtoId,
        'produtoNomeComercial': produtoNomeComercial,
        'produtoNome': produtoNomeComercial,
        'numeroLote': numeroLote,
        'quantidadeDisponivel': quantidadeDisponivel,
        'quantidadeTotal': quantidadeTotal,
        'quantidadeQuarentena': quantidadeQuarentena,
        'estadoSanitario': estadoSanitario,
        'disponibilidade': disponibilidade,
        'dataValidade': dataValidade?.toIso8601String(),
        'precoCompra': precoCompra,
        'precoVenda': precoVenda,
      };
}
