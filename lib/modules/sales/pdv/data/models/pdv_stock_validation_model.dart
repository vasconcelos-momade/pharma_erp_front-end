class PdvStockValidationModel {
  const PdvStockValidationModel({
    required this.permitido,
    required this.estoqueDisponivel,
    required this.quantidadeDisponivel,
    required this.mensagem,
  });

  final bool permitido;
  final bool estoqueDisponivel;
  final int quantidadeDisponivel;
  final String mensagem;

  factory PdvStockValidationModel.fromJson(Map<String, dynamic> json) {
    return PdvStockValidationModel(
      permitido: json['permitido'] as bool? ?? false,
      estoqueDisponivel: json['estoqueDisponivel'] as bool? ?? false,
      quantidadeDisponivel: _toInt(json['quantidadeDisponivel']),
      mensagem: json['mensagem'] as String? ?? 'Falha ao validar stock.',
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString()) ?? 0;
  }
}
