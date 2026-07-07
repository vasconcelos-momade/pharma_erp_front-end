import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';

class QuotationRemoteDataSource {
  QuotationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantCotacoes,
        data: payload,
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida ao criar cotação');
      }
      return ApiEnvelope.unwrapMap(data);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final quotationRemoteDataSourceProvider = Provider<QuotationRemoteDataSource>(
  (ref) => QuotationRemoteDataSource(ref.watch(dioProvider)),
);
