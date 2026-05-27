import 'pdv_cart_line.dart';

/// Carrinho PDV sincronizado com a fatura rascunho no backend.
class PdvCart {
  const PdvCart({
    this.draftFaturaId,
    this.idempotencyKey,
    this.lines = const <PdvCartLine>[],
    this.subtotal = 0,
    this.tax = 0,
    this.discount = 0,
    this.total = 0,
  });

  final String? draftFaturaId;
  final String? idempotencyKey;
  final List<PdvCartLine> lines;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;

  bool get isEmpty => lines.isEmpty;

  String get taxLabel {
    if (tax <= 0) {
      return 'IVA (isento)';
    }
    if (subtotal <= 0) {
      return 'IVA';
    }
    final pct = (tax / subtotal * 100).round();
    return 'IVA ($pct%)';
  }
}
