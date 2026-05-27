import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../../domain/entities/invoice_summary.dart';
import '../models/invoice_summary_model.dart';

abstract class InvoiceRemoteDataSource {
  Future<PaginationResponse<InvoiceSummaryModel>> listInvoices(InvoiceQuery query);

  Future<void> cancelInvoice({
    required String invoiceId,
    required String motivo,
    String? observacoes,
  });
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  InvoiceRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginationResponse<InvoiceSummaryModel>> listInvoices(
    InvoiceQuery query,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPosFaturas,
        queryParameters: <String, dynamic>{
          'page': query.page,
          'pageSize': query.pageSize,
          if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
          if (query.clienteId != null) 'clienteId': query.clienteId,
          if (query.status != null) 'status': query.status,
          if (query.dateFrom != null) 'dateFrom': _formatApiDate(query.dateFrom!),
          if (query.dateTo != null) 'dateTo': _formatApiDate(query.dateTo!),
          if (query.terminalId != null) 'terminalId': query.terminalId,
          if (query.userId != null) 'userId': query.userId,
        },
      );

      final data = response.data;
      if (data == null) {
        return const PaginationResponse<InvoiceSummaryModel>(items: []);
      }

      final rawItems = data['data'];
      final meta = ApiEnvelope.unwrapMeta(data) ?? <String, dynamic>{};
      final items = rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(InvoiceSummaryModel.fromJson)
              .toList()
          : <InvoiceSummaryModel>[];

      return PaginationResponse<InvoiceSummaryModel>(
        items: items,
        page: _asInt(meta['page'], fallback: query.page),
        pageSize: _asInt(meta['pageSize'], fallback: query.pageSize),
        hasMore: meta['hasMore'] == true,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<void> cancelInvoice({
    required String invoiceId,
    required String motivo,
    String? observacoes,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantPosCancelarFatura(invoiceId),
        data: <String, dynamic>{
          'motivo': motivo.trim(),
          if (observacoes != null && observacoes.trim().isNotEmpty)
            'observacoes': observacoes.trim(),
        },
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  String _formatApiDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  int _asInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}

final invoiceRemoteDataSourceProvider = Provider<InvoiceRemoteDataSource>((ref) {
  return InvoiceRemoteDataSourceImpl(ref.watch(dioProvider));
});
