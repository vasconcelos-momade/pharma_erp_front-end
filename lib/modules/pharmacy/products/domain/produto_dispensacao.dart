const List<String> produtoTipoDispensacaoValues = <String>[
  'VENDA_LIVRE',
  'RECEITA_SIMPLES',
  'RECEITA_CONTROLADA',
  'RECEITA_OBRIGATORIA',
  'RECEITA_RETIDA',
  'PSICOTROPICO',
  'NARCOTICO',
];

String produtoTipoDispensacaoLabel(String tipo) {
  switch (tipo) {
    case 'VENDA_LIVRE':
      return 'Venda livre';
    case 'RECEITA_SIMPLES':
      return 'Receita simples';
    case 'RECEITA_CONTROLADA':
      return 'Receita controlada';
    case 'RECEITA_OBRIGATORIA':
      return 'Receita obrigatória';
    case 'RECEITA_RETIDA':
      return 'Receita retida';
    case 'PSICOTROPICO':
      return 'Psicotrópico';
    case 'NARCOTICO':
      return 'Narcótico';
    default:
      return tipo;
  }
}

/// Resumo das regras derivadas (apenas UI; o backend calcula a política completa).
String produtoDispensacaoDerivedSummary(String tipo) {
  switch (tipo) {
    case 'VENDA_LIVRE':
      return 'Sem receita nem livros regulatórios.';
    case 'RECEITA_SIMPLES':
      return 'Receita obrigatória • registo no Livro de Receitas.';
    case 'RECEITA_CONTROLADA':
    case 'RECEITA_OBRIGATORIA':
      return 'Receita obrigatória • dupla validação • Livro de Receitas.';
    case 'RECEITA_RETIDA':
      return 'Receita retida • dupla validação • Livro de Receitas.';
    case 'PSICOTROPICO':
      return 'Receita obrigatória • dupla validação • Livro de Receitas e Psicotrópicos.';
    case 'NARCOTICO':
      return 'Receita obrigatória • dupla validação • livros regulatórios • risco crítico.';
    default:
      return '';
  }
}
