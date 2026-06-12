import '../../domain/entities/fornecedor.dart';

class FornecedorResumoModel {
  const FornecedorResumoModel({
    required this.id,
    required this.nome,
    this.nuit,
    this.telefone,
    this.email,
  });

  final String id;
  final String nome;
  final String? nuit;
  final String? telefone;
  final String? email;

  factory FornecedorResumoModel.fromJson(Map<String, dynamic> json) {
    return FornecedorResumoModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? json['name']?.toString() ?? 'Fornecedor',
      nuit: _nullableString(json['nuit']),
      telefone: _nullableString(json['telefone']),
      email: _nullableString(json['email']),
    );
  }

  FornecedorResumo toEntity() {
    return FornecedorResumo(
      id: id,
      nome: nome,
      nuit: nuit,
      telefone: telefone,
      email: email,
    );
  }
}

String? _nullableString(dynamic value) {
  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}
