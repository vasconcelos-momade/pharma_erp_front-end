import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/auth_session_notifier.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../pharmacy/products/domain/entities/product.dart';
import '../../data/repositories/pdv_cart_repository_impl.dart';
import '../../domain/repositories/pdv_cart_repository.dart';
import '../../domain/entities/pdv_cart.dart';
import '../../domain/entities/pdv_cart_line.dart';
import '../../domain/entities/pdv_service.dart';
import 'caixa_sessao_provider.dart';

class PdvCartState {
  const PdvCartState({
    this.cart = const PdvCart(),
    this.isLoading = false,
    this.isMutating = false,
    this.busyLineId,
  });

  final PdvCart cart;
  final bool isLoading;
  final bool isMutating;
  final String? busyLineId;

  List<PdvCartLine> get lines => cart.lines;

  bool get isEmpty => lines.isEmpty;

  String get taxLabel => cart.taxLabel;

  double get subtotal => cart.subtotal;
  double get tax => cart.tax;
  double get discount => cart.discount;
  double get total => cart.total;
  bool get requiresPatientDetails => cart.requiresPatientDetails;

  bool isLineBusy(String lineId) => isMutating && busyLineId == lineId;

  PdvCartState copyWith({
    PdvCart? cart,
    bool? isLoading,
    bool? isMutating,
    String? busyLineId,
    bool clearBusyLineId = false,
  }) {
    return PdvCartState(
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      busyLineId: clearBusyLineId ? null : (busyLineId ?? this.busyLineId),
    );
  }

  static const initial = PdvCartState();
}

class PdvCartController extends Notifier<PdvCartState> {
  bool _didLoadForSession = false;

  @override
  PdvCartState build() {
    ref.listen(caixaSessaoProvider, (previous, next) {
      if (previous?.hasSessaoAberta == true && !next.hasSessaoAberta) {
        state = PdvCartState.initial;
        _didLoadForSession = false;
      } else if (next.hasSessaoAberta && next.isInitialized) {
        Future.microtask(loadFromServer);
      }
    });

    if (ref.read(caixaSessaoProvider).hasSessaoAberta && !_didLoadForSession) {
      Future.microtask(loadFromServer);
    }

    return PdvCartState.initial;
  }

  ({String userId, String idempotencyKey})? _mutationContext() {
    if (!ref.read(caixaSessaoProvider).hasSessaoAberta) {
      return null;
    }

    final userId = ref.read(authSessionProvider).session?.user.id;
    final sessao = ref.read(caixaSessaoProvider).sessaoAtual;
    if (userId == null || userId.isEmpty || sessao == null) {
      return null;
    }

    final key = state.cart.idempotencyKey ?? 'pdv-$userId-${sessao.id}';
    return (userId: userId, idempotencyKey: key);
  }

  void _applyCart(PdvCart cart) {
    state = state.copyWith(
      cart: cart,
      isLoading: false,
      isMutating: false,
      clearBusyLineId: true,
    );
  }

  Future<void> loadFromServer() async {
    final ctx = _mutationContext();
    if (ctx == null) {
      return;
    }

    state = state.copyWith(isLoading: true, clearBusyLineId: true);

    try {
      final cart = await ref.read(pdvCartRepositoryProvider).getCart(
            userId: ctx.userId,
            idempotencyKey: ctx.idempotencyKey,
          );
      _didLoadForSession = true;
      _applyCart(cart.copyWith(idempotencyKey: ctx.idempotencyKey));
    } on ApiFailure {
      state = state.copyWith(isLoading: false, clearBusyLineId: true);
      rethrow;
    } catch (_) {
      state = state.copyWith(isLoading: false, clearBusyLineId: true);
      rethrow;
    }
  }

  Future<bool> addProduct(Product product) async {
    final ctx = _mutationContext();
    if (ctx == null) {
      return false;
    }

    final lineId = 'produto:${product.id}';
    state = state.copyWith(isMutating: true, busyLineId: lineId);

    try {
      final cart = await ref.read(pdvCartRepositoryProvider).addItem(
            userId: ctx.userId,
            idempotencyKey: ctx.idempotencyKey,
            product: product,
          );
      _applyCart(cart.copyWith(idempotencyKey: ctx.idempotencyKey));
      return true;
    } on ApiFailure {
      state = state.copyWith(isMutating: false, clearBusyLineId: true);
      rethrow;
    } catch (_) {
      state = state.copyWith(isMutating: false, clearBusyLineId: true);
      rethrow;
    }
  }

  Future<bool> addService(PdvService service) async {
    final ctx = _mutationContext();
    if (ctx == null) {
      return false;
    }

    final lineId = 'servico:${service.id}';
    state = state.copyWith(isMutating: true, busyLineId: lineId);

    try {
      final cart = await ref.read(pdvCartRepositoryProvider).addService(
            userId: ctx.userId,
            idempotencyKey: ctx.idempotencyKey,
            service: service,
          );
      _applyCart(cart.copyWith(idempotencyKey: ctx.idempotencyKey));
      return true;
    } on ApiFailure {
      state = state.copyWith(isMutating: false, clearBusyLineId: true);
      rethrow;
    } catch (_) {
      state = state.copyWith(isMutating: false, clearBusyLineId: true);
      rethrow;
    }
  }

  Future<bool> incrementLine(PdvCartLine line) async {
    if (!line.canMutateViaApi) {
      throw const ApiFailure('Item não sincronizado com o servidor.');
    }
    return _mutateItem(line, (repo, ctx) => repo.incrementItem(
          userId: ctx.userId,
          idempotencyKey: ctx.idempotencyKey,
          itemId: line.faturaItemId!,
        ));
  }

  Future<bool> decrementLine(PdvCartLine line) async {
    if (!line.canMutateViaApi) {
      throw const ApiFailure('Item não sincronizado com o servidor.');
    }
    return _mutateItem(line, (repo, ctx) => repo.decrementItem(
          userId: ctx.userId,
          idempotencyKey: ctx.idempotencyKey,
          itemId: line.faturaItemId!,
        ));
  }

  Future<bool> removeLine(PdvCartLine line) async {
    if (!line.canMutateViaApi) {
      throw const ApiFailure('Item não sincronizado com o servidor.');
    }
    return _mutateItem(line, (repo, ctx) => repo.removeItem(
          userId: ctx.userId,
          idempotencyKey: ctx.idempotencyKey,
          itemId: line.faturaItemId!,
        ));
  }

  Future<bool> _mutateItem(
    PdvCartLine line,
    Future<PdvCart> Function(
      PdvCartRepository repo,
      ({String userId, String idempotencyKey}) ctx,
    ) mutate,
  ) async {
    final ctx = _mutationContext();
    if (ctx == null) {
      return false;
    }

    state = state.copyWith(isMutating: true, busyLineId: line.id);

    try {
      final cart = await mutate(ref.read(pdvCartRepositoryProvider), ctx);
      _applyCart(cart.copyWith(idempotencyKey: ctx.idempotencyKey));
      return true;
    } on ApiFailure {
      state = state.copyWith(isMutating: false, clearBusyLineId: true);
      rethrow;
    } catch (_) {
      state = state.copyWith(isMutating: false, clearBusyLineId: true);
      rethrow;
    }
  }

  void clear() {
    state = PdvCartState.initial;
    _didLoadForSession = false;
  }

  void applyCheckoutReset(String nextCartIdempotencyKey) {
    if (nextCartIdempotencyKey.isEmpty) {
      clear();
      return;
    }

    state = PdvCartState(
      cart: PdvCart(idempotencyKey: nextCartIdempotencyKey),
      isLoading: false,
      isMutating: false,
    );
    _didLoadForSession = true;
  }
}

extension on PdvCart {
  PdvCart copyWith({
    String? idempotencyKey,
  }) {
    return PdvCart(
      draftFaturaId: draftFaturaId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      lines: lines,
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total,
      taxLabel: taxLabel,
      requiresPatientDetails: requiresPatientDetails,
    );
  }
}

final pdvCartProvider =
    NotifierProvider<PdvCartController, PdvCartState>(PdvCartController.new);
