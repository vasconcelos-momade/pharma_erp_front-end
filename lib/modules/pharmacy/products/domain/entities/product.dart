import 'product_tax_rule.dart';

class Product {
  final String id;
  final String nome;
  final String? substanciaActiva;
  final String? dosagem;
  final String? forma;
  final String? apresentacao;
  final bool ativo;
  final String? barcode;
  final String tipoDispensacao;
  final bool requiresPrescription;
  final bool requiresDoubleCheck;
  final bool requiresPsychotropicBook;
  final double precoVenda;
  final double estoqueAtual;
  final double estoqueMinimo;
  final String? lote;
  final DateTime? dataValidade;
  final DateTime? createdAt;
  final ProductTaxRule? taxRule;

  Product({
    required this.id,
    required this.nome,
    this.substanciaActiva,
    this.dosagem,
    this.forma,
    this.apresentacao,
    required this.ativo,
    this.barcode,
    required this.tipoDispensacao,
    required this.requiresPrescription,
    required this.requiresDoubleCheck,
    required this.requiresPsychotropicBook,
    required this.precoVenda,
    required this.estoqueAtual,
    required this.estoqueMinimo,
    this.lote,
    this.dataValidade,
    this.createdAt,
    this.taxRule,
  });

  bool get isOutOfStock => estoqueAtual <= 0;

  bool get isPsychotropic =>
      tipoDispensacao == 'PSICOTROPICO' ||
      tipoDispensacao == 'NARCOTICO' ||
      requiresPsychotropicBook;
}
