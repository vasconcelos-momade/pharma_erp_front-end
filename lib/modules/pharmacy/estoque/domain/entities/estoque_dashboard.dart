class EstoqueDashboard {
  const EstoqueDashboard({
    required this.produtosEmStock,
    required this.lotesAtivos,
    required this.produtosSemStock,
    required this.lotesAExpirar,
    required this.lotesExpirados,
    required this.valorTotalInventario,
  });

  final int produtosEmStock;
  final int lotesAtivos;
  final int produtosSemStock;
  final int lotesAExpirar;
  final int lotesExpirados;
  final num valorTotalInventario;
}
