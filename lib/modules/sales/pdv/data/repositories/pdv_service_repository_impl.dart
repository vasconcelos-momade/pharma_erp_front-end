import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pdv_service.dart';
import '../../domain/repositories/pdv_service_repository.dart';
import '../datasources/pdv_service_remote_datasource.dart';
import '../models/pdv_service_model.dart';

class PdvServiceRepositoryImpl implements PdvServiceRepository {
  PdvServiceRepositoryImpl(this._remoteDataSource);

  final PdvServiceRemoteDataSource _remoteDataSource;

  @override
  Future<List<PdvService>> searchServices({
    String? query,
  }) async {
    final response = await _remoteDataSource.searchServices(query: query);
    return response.map(_toEntity).toList();
  }

  PdvService _toEntity(PdvServiceModel model) {
    return PdvService(
      id: model.id,
      nome: model.nome,
      preco: model.preco,
      tipoServicoClinico: model.tipoServicoClinico,
    );
  }
}

final pdvServiceRepositoryProvider = Provider<PdvServiceRepository>((ref) {
  return PdvServiceRepositoryImpl(ref.watch(pdvServiceRemoteDataSourceProvider));
});
