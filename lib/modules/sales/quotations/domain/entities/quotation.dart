class QuotationSummary {
  const QuotationSummary({
    required this.id,
    required this.numero,
    required this.estado,
    required this.clienteNome,
    required this.total,
    required this.validade,
    required this.createdAt,
    this.itemCount = 0,
  });

  final String id;
  final String numero;
  final String estado;
  final String clienteNome;
  final double total;
  final DateTime validade;
  final DateTime createdAt;
  final int itemCount;
}

class QuotationCreateResult {
  const QuotationCreateResult({
    required this.id,
    required this.numero,
    required this.total,
  });

  final String id;
  final String numero;
  final double total;
}
