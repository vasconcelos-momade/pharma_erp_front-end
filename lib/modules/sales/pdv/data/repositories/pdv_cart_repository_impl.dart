import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../pharmacy/products/domain/entities/product.dart';
import '../../domain/entities/pdv_cart.dart';
import '../../domain/entities/pdv_checkout.dart';
import '../../domain/entities/pdv_service.dart';
import '../../domain/mappers/draft_cart_mapper.dart';
import '../../domain/repositories/pdv_cart_repository.dart';
import '../datasources/pdv_remote_datasource.dart';
import '../models/finalizar_venda_model.dart';

class PdvCartRepositoryImpl implements PdvCartRepository {
  PdvCartRepositoryImpl(this._remote);

  final PdvRemoteDataSource _remote;

  @override
  Future<PdvCart> getCart({
    required String userId,
    required String idempotencyKey,
  }) async {
    final model = await _remote.getDraftCart(idempotencyKey: idempotencyKey);
    return DraftCartMapper.toEntity(model);
  }

  @override
  Future<PdvCart> addItem({
    required String userId,
    required String idempotencyKey,
    required Product product,
    int quantidade = 1,
  }) async {
    final model = await _remote.addDraftCartItem(
      idempotencyKey: idempotencyKey,
      produtoId: product.id,
      quantidade: quantidade,
    );
    return DraftCartMapper.toEntity(model);
  }

  @override
  Future<PdvCart> addService({
    required String userId,
    required String idempotencyKey,
    required PdvService service,
    int quantidade = 1,
  }) async {
    final model = await _remote.addDraftCartItem(
      idempotencyKey: idempotencyKey,
      servicoId: service.id,
      quantidade: quantidade,
    );
    return DraftCartMapper.toEntity(model);
  }

  @override
  Future<PdvCart> incrementItem({
    required String userId,
    required String idempotencyKey,
    required String itemId,
  }) async {
    final model = await _remote.incrementDraftCartItem(
      idempotencyKey: idempotencyKey,
      itemId: itemId,
    );
    return DraftCartMapper.toEntity(model);
  }

  @override
  Future<PdvCart> decrementItem({
    required String userId,
    required String idempotencyKey,
    required String itemId,
  }) async {
    final model = await _remote.decrementDraftCartItem(
      idempotencyKey: idempotencyKey,
      itemId: itemId,
    );
    return DraftCartMapper.toEntity(model);
  }

  @override
  Future<PdvCart> removeItem({
    required String userId,
    required String idempotencyKey,
    required String itemId,
  }) async {
    final model = await _remote.removeDraftCartItem(
      idempotencyKey: idempotencyKey,
      itemId: itemId,
    );
    return DraftCartMapper.toEntity(model);
  }

  @override
  Future<PdvCheckoutResult> finalizarVenda({
    required String terminalId,
    required String idempotencyKey,
    required PdvPaymentMethod metodoPagamento,
    PdvCheckoutPatient? paciente,
    double? valorRecebido,
  }) async {
    final response = await _remote.finalizarVenda(
      FinalizarVendaRequestModel(
        terminalId: terminalId,
        metodoPagamento: _toMetodoPagamentoModel(metodoPagamento),
        idempotencyKey: idempotencyKey,
        valorRecebido: valorRecebido,
        paciente: paciente == null
            ? null
            : PacienteCheckoutModel(
                nome: paciente.nome,
                idade: paciente.idade,
                nid: paciente.nid,
              ),
        receita: paciente == null
            ? null
            : ReceitaCheckoutModel(
                numero: paciente.nid,
                prescritor: paciente.prescritor,
                unidadeSanitaria: paciente.unidadeSanitaria,
              ),
      ),
    );

    return PdvCheckoutResult(
      id: response.id,
      numero: response.numero,
      estado: response.estado,
      subtotal: response.subtotal,
      ivaTotal: response.ivaTotal,
      total: response.total,
      troco: response.troco,
      items: response.items
          .map(
            (line) => PdvCheckoutLine(
              tipo: line.tipo,
              produtoId: line.produtoId,
              servicoId: line.servicoId,
              descricao: line.descricao,
              quantidade: line.quantidade,
              precoUnit: line.precoUnit,
              total: line.total,
            ),
          )
          .toList(),
      cartReset: response.cartReset,
      nextCartIdempotencyKey: response.nextCartIdempotencyKey,
    );
  }

  MetodoPagamentoModel _toMetodoPagamentoModel(PdvPaymentMethod method) {
    switch (method) {
      case PdvPaymentMethod.dinheiro:
        return MetodoPagamentoModel.dinheiro;
      case PdvPaymentMethod.mpesa:
        return MetodoPagamentoModel.mpesa;
      case PdvPaymentMethod.emola:
        return MetodoPagamentoModel.emola;
      case PdvPaymentMethod.cartao:
        return MetodoPagamentoModel.cartao;
    }
  }
}

final pdvCartRepositoryProvider = Provider<PdvCartRepository>((ref) {
  return PdvCartRepositoryImpl(ref.watch(pdvRemoteDataSourceProvider));
});
