class FornecedorResumo {
  const FornecedorResumo({
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
}
