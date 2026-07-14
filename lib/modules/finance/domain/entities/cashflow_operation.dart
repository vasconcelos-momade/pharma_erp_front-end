class CashflowOrigemOption {
  const CashflowOrigemOption({required this.value, required this.label});

  final String value;
  final String label;

  factory CashflowOrigemOption.fromJson(Map<String, dynamic> json) {
    return CashflowOrigemOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class CashflowTerminalContext {
  const CashflowTerminalContext({
    required this.id,
    required this.codigo,
    required this.nome,
    this.localizacao,
  });

  final String id;
  final String codigo;
  final String nome;
  final String? localizacao;

  factory CashflowTerminalContext.fromJson(Map<String, dynamic> json) {
    return CashflowTerminalContext(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      localizacao: json['localizacao']?.toString(),
    );
  }
}

class CashflowContext {
  const CashflowContext({
    required this.sessaoId,
    required this.caixaId,
    required this.saldoAtual,
    required this.saldoTotal,
    required this.terminal,
    required this.origens,
  });

  final String sessaoId;
  final String caixaId;
  final num saldoAtual;
  final num saldoTotal;
  final CashflowTerminalContext terminal;
  final List<CashflowOrigemOption> origens;

  factory CashflowContext.fromJson(Map<String, dynamic> json) {
    final rawOrigens = json['origens'];
    return CashflowContext(
      sessaoId: json['sessaoId']?.toString() ?? '',
      caixaId: json['caixaId']?.toString() ?? '',
      saldoAtual: json['saldoAtual'] as num? ?? 0,
      saldoTotal: json['saldoTotal'] as num? ?? 0,
      terminal: CashflowTerminalContext.fromJson(
        json['terminal'] as Map<String, dynamic>? ?? const {},
      ),
      origens: rawOrigens is List
          ? rawOrigens
              .whereType<Map<String, dynamic>>()
              .map(CashflowOrigemOption.fromJson)
              .toList()
          : const [],
    );
  }
}

class CashflowOperationRequest {
  const CashflowOperationRequest({
    required this.valor,
    required this.origem,
    this.descricao,
    this.idempotencyKey,
  });

  final num valor;
  final String origem;
  final String? descricao;
  final String? idempotencyKey;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'valor': valor,
        'origem': origem,
        if (descricao != null && descricao!.trim().isNotEmpty)
          'descricao': descricao!.trim(),
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      };
}

class CashflowOperationResponse {
  const CashflowOperationResponse({
    required this.movimentoId,
    required this.saldoAtual,
    required this.valor,
    required this.kind,
    required this.origem,
  });

  final String movimentoId;
  final num saldoAtual;
  final num valor;
  final String kind;
  final String origem;

  factory CashflowOperationResponse.fromJson(Map<String, dynamic> json) {
    return CashflowOperationResponse(
      movimentoId: json['movimentoId']?.toString() ?? '',
      saldoAtual: json['saldoAtual'] as num? ?? 0,
      valor: json['valor'] as num? ?? 0,
      kind: json['kind']?.toString() ?? '',
      origem: json['origem']?.toString() ?? '',
    );
  }
}

String? defaultCashflowOrigemForOperation(String operationType) {
  return switch (operationType) {
    'Suprimento' => 'REFORCO',
    'Sangria' => 'SANGRIA',
    'Extorno' => 'OUTRO',
    _ => null,
  };
}

String cashflowOperationEndpointKey(String operationType) {
  return switch (operationType) {
    'Saída' => 'saida',
    'Suprimento' => 'suprimento',
    'Sangria' => 'sangria',
    'Extorno' => 'estorno',
    _ => 'saida',
  };
}
