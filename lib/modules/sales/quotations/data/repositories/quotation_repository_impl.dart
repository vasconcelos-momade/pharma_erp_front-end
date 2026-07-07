import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/quotation.dart';
import '../../domain/entities/quotation_cart_line.dart';
import '../../domain/repositories/quotation_repository.dart';
import '../datasources/quotation_remote_datasource.dart';

class QuotationRepositoryImpl implements QuotationRepository {
  QuotationRepositoryImpl(this._remote);

  final QuotationRemoteDataSource _remote;

  @override
  Future<QuotationCreateResult> createQuotation({
    required String clienteId,
    required DateTime validade,
    String? observacoes,
    required List<QuotationCartLine> lines,
  }) async {
    final payload = <String, dynamic>{
      'clienteId': clienteId,
      'validade': validade.toUtc().toIso8601String(),
      if (observacoes != null && observacoes.trim().isNotEmpty)
        'observacoes': observacoes.trim(),
      'items': lines
          .map(
            (line) => <String, dynamic>{
              if (line.product != null) 'produtoId': line.product!.id,
              if (line.service != null) 'servicoId': line.service!.id,
              'quantidade': line.quantidade,
              'precoUnit': line.effectivePrecoUnit,
            },
          )
          .toList(growable: false),
    };

    final data = await _remote.create(payload);
    return QuotationCreateResult(
      id: data['id']?.toString() ?? '',
      numero: data['numero']?.toString() ?? '',
      total: _toDouble(data['total']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }
}

final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  return QuotationRepositoryImpl(ref.watch(quotationRemoteDataSourceProvider));
});
