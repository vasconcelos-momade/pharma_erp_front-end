/// Regra fiscal associada ao produto (espelho do backend).
class ProductTaxRule {
  const ProductTaxRule({
    required this.tipo,
    required this.taxa,
    this.codigo,
  });

  final String tipo;
  /// Taxa em percentual (ex.: 16) ou decimal (0.16).
  final double taxa;
  final String? codigo;

  bool get isExempt =>
      tipo == 'IVA_ISENTO' ||
      tipo == 'NAO_TRIBUTAVEL' ||
      taxa <= 0;
}
