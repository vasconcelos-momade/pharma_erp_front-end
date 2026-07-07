import '../../../../pharmacy/products/domain/entities/product.dart';
import '../../../../pharmacy/products/domain/entities/product_tax_rule.dart';
import '../../../pdv/domain/entities/pdv_service.dart';
import '../services/quotation_fiscal_calculator.dart';

/// Linha local da cotação (produto ou serviço).
class QuotationCartLine {
  QuotationCartLine({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.unidade,
    required this.quantidade,
    required this.precoUnitario,
    this.descontoPercent = 0,
    this.observacao,
    this.ativo = true,
    this.product,
    this.service,
    this.taxRule,
    this.allowPriceEdit = true,
  });

  final String id;
  final String nome;
  final String codigo;
  final String unidade;
  final double quantidade;
  final double precoUnitario;
  final double descontoPercent;
  final String? observacao;
  final bool ativo;
  final Product? product;
  final PdvService? service;
  final ProductTaxRule? taxRule;
  final bool allowPriceEdit;

  bool get isProduct => product != null;

  QuotationFiscalResult get fiscal => QuotationFiscalCalculator.calculate(
        quantidade: quantidade,
        precoUnitario: precoUnitario,
        descontoPercent: descontoPercent,
        taxRule: taxRule,
      );

  double get subtotal => fiscal.baseCalculo;
  double get descontoValor => fiscal.descontoValor;
  double get valorIva => fiscal.valorIva;
  double get total => fiscal.total;
  String get ivaLabel => fiscal.ivaLabel;

  factory QuotationCartLine.fromProduct(Product product, {double quantidade = 1}) {
    return QuotationCartLine(
      id: 'produto:${product.id}',
      nome: product.nomeComercial,
      codigo: product.barcode ?? product.id,
      unidade: 'un',
      quantidade: quantidade,
      precoUnitario: product.precoVenda,
      ativo: product.ativo,
      product: product,
      taxRule: product.taxRule,
    );
  }

  factory QuotationCartLine.fromService(PdvService service, {double quantidade = 1}) {
    return QuotationCartLine(
      id: 'servico:${service.id}',
      nome: service.nome,
      codigo: service.id,
      unidade: 'un',
      quantidade: quantidade,
      precoUnitario: service.preco,
      ativo: true,
      service: service,
      taxRule: const ProductTaxRule(tipo: 'IVA_NORMAL', taxa: 16),
    );
  }

  QuotationCartLine copyWith({
    double? quantidade,
    double? precoUnitario,
    double? descontoPercent,
    String? observacao,
    bool clearObservacao = false,
  }) {
    return QuotationCartLine(
      id: id,
      nome: nome,
      codigo: codigo,
      unidade: unidade,
      quantidade: quantidade ?? this.quantidade,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      descontoPercent: descontoPercent ?? this.descontoPercent,
      observacao: clearObservacao ? null : (observacao ?? this.observacao),
      ativo: ativo,
      product: product,
      service: service,
      taxRule: taxRule,
      allowPriceEdit: allowPriceEdit,
    );
  }

  /// Preço unitário efectivo para persistência (desconto incorporado).
  double get effectivePrecoUnit {
    if (descontoPercent <= 0) {
      return precoUnitario;
    }
    return precoUnitario * (1 - descontoPercent.clamp(0, 100) / 100);
  }
}
