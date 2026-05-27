import '../../../../pharmacy/products/domain/entities/product_tax_rule.dart';

class DraftCartItemModel {
  const DraftCartItemModel({
    required this.id,
    required this.tipo,
    this.produtoId,
    this.servicoId,
    this.loteId,
    required this.nome,
    required this.quantidade,
    required this.precoUnit,
    required this.baseCalculo,
    required this.valorIva,
    required this.total,
    required this.ivaPercentual,
    this.taxRule,
    required this.requiresPrescription,
    this.estoqueAtual,
    this.estoqueDisponivel,
    this.tipoServicoClinico,
  });

  final String id;
  final String tipo;
  final String? produtoId;
  final String? servicoId;
  final String? loteId;
  final String nome;
  final int quantidade;
  final double precoUnit;
  final double baseCalculo;
  final double valorIva;
  final double total;
  final double ivaPercentual;
  final ProductTaxRule? taxRule;
  final bool requiresPrescription;
  final double? estoqueAtual;
  final double? estoqueDisponivel;
  final String? tipoServicoClinico;

  bool get isProduto => tipo == 'produto';
  bool get isServico => tipo == 'servico';

  factory DraftCartItemModel.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipo'] as String? ??
        (json['servicoId'] != null ? 'servico' : 'produto');

    return DraftCartItemModel(
      id: json['id'].toString(),
      tipo: tipo,
      produtoId: json['produtoId']?.toString(),
      servicoId: json['servicoId']?.toString(),
      loteId: json['loteId']?.toString(),
      nome: json['nome'] as String? ?? '',
      quantidade: _toInt(json['quantidade']),
      precoUnit: _toDouble(json['precoUnit']),
      baseCalculo: _toDouble(json['baseCalculo']),
      valorIva: _toDouble(json['valorIva']),
      total: _toDouble(json['total']),
      ivaPercentual: _toDouble(json['ivaPercentual']),
      taxRule: _parseTaxRule(json['taxRule']),
      requiresPrescription: json['requiresPrescription'] as bool? ?? false,
      estoqueAtual: json['estoqueAtual'] == null ? null : _toDouble(json['estoqueAtual']),
      estoqueDisponivel:
          json['estoqueDisponivel'] == null ? null : _toDouble(json['estoqueDisponivel']),
      tipoServicoClinico: json['tipoServicoClinico'] as String?,
    );
  }

  static ProductTaxRule? _parseTaxRule(dynamic value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    return ProductTaxRule(
      tipo: value['tipo'] as String? ?? 'IVA_NORMAL',
      taxa: _toDouble(value['taxa']),
      codigo: value['codigo'] as String?,
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
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

class DraftCartModel {
  const DraftCartModel({
    required this.id,
    required this.numero,
    required this.estado,
    this.idempotencyKey,
    required this.subtotal,
    required this.desconto,
    required this.ivaTotal,
    required this.total,
    required this.items,
  });

  final String id;
  final String numero;
  final String estado;
  final String? idempotencyKey;
  final double subtotal;
  final double desconto;
  final double ivaTotal;
  final double total;
  final List<DraftCartItemModel> items;

  bool get hasDraft => id.isNotEmpty;

  factory DraftCartModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(DraftCartItemModel.fromJson)
            .toList()
        : <DraftCartItemModel>[];

    return DraftCartModel(
      id: json['id']?.toString() ?? '',
      numero: json['numero'] as String? ?? '',
      estado: json['estado'] as String? ?? 'RASCUNHO',
      idempotencyKey: json['idempotencyKey'] as String?,
      subtotal: DraftCartItemModel._toDouble(json['subtotal']),
      desconto: DraftCartItemModel._toDouble(json['desconto']),
      ivaTotal: DraftCartItemModel._toDouble(json['ivaTotal']),
      total: DraftCartItemModel._toDouble(json['total']),
      items: items,
    );
  }

  factory DraftCartModel.empty({String? idempotencyKey}) {
    return DraftCartModel(
      id: '',
      numero: '',
      estado: 'RASCUNHO',
      idempotencyKey: idempotencyKey,
      subtotal: 0,
      desconto: 0,
      ivaTotal: 0,
      total: 0,
      items: const [],
    );
  }
}

class DraftCartItemRequestModel {
  const DraftCartItemRequestModel({
    required this.idempotencyKey,
    this.produtoId,
    this.servicoId,
    this.loteId,
    this.quantidade,
  });

  final String idempotencyKey;
  final String? produtoId;
  final String? servicoId;
  final String? loteId;
  final int? quantidade;

  Map<String, dynamic> toJson() => {
        'idempotencyKey': idempotencyKey,
        if (produtoId != null) 'produtoId': produtoId,
        if (servicoId != null) 'servicoId': servicoId,
        if (loteId != null) 'loteId': loteId,
        if (quantidade != null) 'quantidade': quantidade,
      };
}

class DraftCartContextRequestModel {
  const DraftCartContextRequestModel({required this.idempotencyKey});

  final String idempotencyKey;

  Map<String, dynamic> toJson() => {'idempotencyKey': idempotencyKey};
}
