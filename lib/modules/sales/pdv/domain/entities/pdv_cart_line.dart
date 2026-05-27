import '../../../../pharmacy/products/domain/entities/product.dart';
import 'pdv_service.dart';

/// Linha do carrinho PDV (produto ou serviço).
class PdvCartLine {
  const PdvCartLine._({
    required this.id,
    required this.nome,
    required this.precoUnitario,
    required this.qty,
    this.faturaItemId,
    this.product,
    this.service,
  });

  factory PdvCartLine.product(
    Product product,
    int qty, {
    String? faturaItemId,
  }) {
    return PdvCartLine._(
      id: 'produto:${product.id}',
      faturaItemId: faturaItemId,
      nome: product.nome,
      precoUnitario: product.precoVenda,
      qty: qty,
      product: product,
    );
  }

  factory PdvCartLine.fromCatalogProduct(Product product, int qty) =>
      PdvCartLine.product(product, qty);

  factory PdvCartLine.service(
    PdvService service,
    int qty, {
    String? faturaItemId,
  }) {
    return PdvCartLine._(
      id: 'servico:${service.id}',
      faturaItemId: faturaItemId,
      nome: service.nome,
      precoUnitario: service.preco,
      qty: qty,
      service: service,
    );
  }

  final String id;
  final String nome;
  final double precoUnitario;
  final int qty;
  /// ID do `fatura_itens` no backend (obrigatório para +/- e remover via API).
  final String? faturaItemId;
  final Product? product;
  final PdvService? service;

  bool get isProduct => product != null;

  bool get canMutateViaApi =>
      faturaItemId != null && faturaItemId!.isNotEmpty;
}
