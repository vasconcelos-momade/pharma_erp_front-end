enum PdvPaymentMethod {
  dinheiro,
  mpesa,
  emola,
  cartao,
}

class PdvCheckoutPatient {
  const PdvCheckoutPatient({
    required this.nome,
    required this.idade,
    required this.nid,
    required this.prescritor,
    required this.unidadeSanitaria,
  });

  final String nome;
  final int idade;
  final String nid;
  final String prescritor;
  final String unidadeSanitaria;
}

class PdvCheckoutLine {
  const PdvCheckoutLine({
    required this.tipo,
    required this.descricao,
    required this.quantidade,
    required this.precoUnit,
    required this.total,
    this.produtoId,
    this.servicoId,
  });

  final String tipo;
  final String? produtoId;
  final String? servicoId;
  final String descricao;
  final int quantidade;
  final double precoUnit;
  final double total;
}

class PdvCheckoutResult {
  const PdvCheckoutResult({
    required this.id,
    required this.numero,
    required this.estado,
    required this.subtotal,
    required this.ivaTotal,
    required this.total,
    this.items = const [],
    required this.cartReset,
    required this.nextCartIdempotencyKey,
  });

  final String id;
  final String numero;
  final String estado;
  final double subtotal;
  final double ivaTotal;
  final double total;
  final List<PdvCheckoutLine> items;
  final bool cartReset;
  final String nextCartIdempotencyKey;
}
