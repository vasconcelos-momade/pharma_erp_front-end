import 'quotation_cart_line.dart';

class QuotationCart {
  const QuotationCart({this.lines = const <QuotationCartLine>[]});

  final List<QuotationCartLine> lines;

  int get itemCount => lines.length;

  double get unitsCount =>
      lines.fold<double>(0, (sum, line) => sum + line.quantidade);

  double get subtotal =>
      lines.fold<double>(0, (sum, line) => sum + line.subtotal);

  double get descontoTotal =>
      lines.fold<double>(0, (sum, line) => sum + line.descontoValor);

  double get ivaTotal =>
      lines.fold<double>(0, (sum, line) => sum + line.valorIva);

  double get total => lines.fold<double>(0, (sum, line) => sum + line.total);

  bool get isEmpty => lines.isEmpty;

  QuotationCart copyWith({List<QuotationCartLine>? lines}) {
    return QuotationCart(lines: lines ?? this.lines);
  }
}
