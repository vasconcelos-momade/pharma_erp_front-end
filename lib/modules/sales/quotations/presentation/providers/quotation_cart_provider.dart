import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../pharmacy/products/domain/entities/product.dart';
import '../../../pdv/domain/entities/pdv_service.dart';
import '../../domain/entities/quotation_cart.dart';
import '../../domain/entities/quotation_cart_line.dart';

class QuotationCartState {
  const QuotationCartState({
    this.cart = const QuotationCart(),
    this.isSaving = false,
  });

  final QuotationCart cart;
  final bool isSaving;

  List<QuotationCartLine> get lines => cart.lines;
  bool get isEmpty => cart.isEmpty;
  int get itemCount => cart.itemCount;
  double get subtotal => cart.subtotal;
  double get descontoTotal => cart.descontoTotal;
  double get ivaTotal => cart.ivaTotal;
  double get total => cart.total;

  QuotationCartState copyWith({
    QuotationCart? cart,
    bool? isSaving,
  }) {
    return QuotationCartState(
      cart: cart ?? this.cart,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class QuotationCartController extends Notifier<QuotationCartState> {
  @override
  QuotationCartState build() => const QuotationCartState();

  void addProduct(Product product) {
    final existingIndex =
        state.lines.indexWhere((line) => line.id == 'produto:${product.id}');
    if (existingIndex >= 0) {
      final existing = state.lines[existingIndex];
      _updateLine(
        existingIndex,
        existing.copyWith(quantidade: existing.quantidade + 1),
      );
      return;
    }

    final next = [
      ...state.lines,
      QuotationCartLine.fromProduct(product),
    ];
    state = state.copyWith(cart: QuotationCart(lines: next));
  }

  void addService(PdvService service) {
    final existingIndex =
        state.lines.indexWhere((line) => line.id == 'servico:${service.id}');
    if (existingIndex >= 0) {
      final existing = state.lines[existingIndex];
      _updateLine(
        existingIndex,
        existing.copyWith(quantidade: existing.quantidade + 1),
      );
      return;
    }

    final next = [
      ...state.lines,
      QuotationCartLine.fromService(service),
    ];
    state = state.copyWith(cart: QuotationCart(lines: next));
  }

  void incrementLine(QuotationCartLine line) {
    final index = state.lines.indexWhere((item) => item.id == line.id);
    if (index < 0) {
      return;
    }
    final current = state.lines[index];
    _updateLine(index, current.copyWith(quantidade: current.quantidade + 1));
  }

  void decrementLine(QuotationCartLine line) {
    final index = state.lines.indexWhere((item) => item.id == line.id);
    if (index < 0) {
      return;
    }
    final current = state.lines[index];
    if (current.quantidade <= 1) {
      removeLine(line);
      return;
    }
    _updateLine(index, current.copyWith(quantidade: current.quantidade - 1));
  }

  void removeLine(QuotationCartLine line) {
    final next = state.lines.where((item) => item.id != line.id).toList();
    state = state.copyWith(cart: QuotationCart(lines: next));
  }

  void updateLine(QuotationCartLine line) {
    final index = state.lines.indexWhere((item) => item.id == line.id);
    if (index < 0) {
      return;
    }
    _updateLine(index, line);
  }

  void clear() {
    state = const QuotationCartState();
  }

  void setSaving(bool value) {
    state = state.copyWith(isSaving: value);
  }

  void _updateLine(int index, QuotationCartLine line) {
    final next = List<QuotationCartLine>.of(state.lines);
    next[index] = line;
    state = state.copyWith(cart: QuotationCart(lines: next));
  }
}

final quotationCartProvider =
    NotifierProvider<QuotationCartController, QuotationCartState>(
  QuotationCartController.new,
);
