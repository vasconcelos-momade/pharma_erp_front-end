/// Leitura de stock por lote a partir dos contratos actuais da API
/// (`LoteStockBalance`: `quantidadeTotal`, `quantidadeDisponivel`).
class LoteStockUtils {
  LoteStockUtils._();

  static double readDisponivel(Map<String, dynamic>? data) {
    if (data == null) {
      return 0;
    }
    return _toDouble(data['quantidadeDisponivel']);
  }

  static double readTotal(Map<String, dynamic>? data) {
    if (data == null) {
      return 0;
    }
    return _toDouble(data['quantidadeTotal']);
  }

  static String formatDisponivel(Map<String, dynamic>? data) {
    return readDisponivel(data).toString();
  }

  static String formatTotal(Map<String, dynamic>? data) {
    return readTotal(data).toString();
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
