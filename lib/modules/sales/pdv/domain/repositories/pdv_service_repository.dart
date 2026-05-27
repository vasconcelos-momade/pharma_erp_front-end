import '../entities/pdv_service.dart';

abstract class PdvServiceRepository {
  Future<List<PdvService>> searchServices({
    String? query,
  });
}
