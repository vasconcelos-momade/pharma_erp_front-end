import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../models/pdv_service_model.dart';

abstract class PdvServiceRemoteDataSource {
  Future<List<PdvServiceModel>> searchServices({
    String? query,
  });
}

class PdvServiceRemoteDataSourceImpl implements PdvServiceRemoteDataSource {
  PdvServiceRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<PdvServiceModel>> searchServices({
    String? query,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPosServicosSearch,
        queryParameters: <String, dynamic>{
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        },
      );

      final data = response.data;
      if (data == null) {
        return <PdvServiceModel>[];
      }
      final payload = ApiEnvelope.unwrapMap(data);
      final items = payload['items'] as List<dynamic>? ?? ApiEnvelope.unwrapList(data);
      return items
          .map((json) => PdvServiceModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final pdvServiceRemoteDataSourceProvider = Provider<PdvServiceRemoteDataSource>((ref) {
  return PdvServiceRemoteDataSourceImpl(ref.watch(dioProvider));
});
