import '../../domain/entities/compra.dart';

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
      id: _stringValue(json, const ['id']),
      nome: _stringValue(json, const ['nome'], fallback: 'Fornecedor'),
      nuit: _nullableString(_dynamicValue(json, const ['nuit'])),
      telefone: _nullableString(_dynamicValue(json, const ['telefone'])),
      email: _nullableString(_dynamicValue(json, const ['email'])),
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

class CriarCompraPendenteRequestModel {
  const CriarCompraPendenteRequestModel({
    required this.fornecedorId,
  });

  final String fornecedorId;

  factory CriarCompraPendenteRequestModel.fromEntity(
    CriarCompraPendenteRequest entity,
  ) {
    return CriarCompraPendenteRequestModel(
      fornecedorId: entity.fornecedorId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fornecedorId': fornecedorId,
    };
  }
}

class CompraItemRequestModel {
  const CompraItemRequestModel({
    required this.produtoId,
    required this.numeroLote,
    required this.dataValidade,
    required this.quantidade,
    required this.precoCompra,
    this.precoVenda,
  });

  final String produtoId;
  final String numeroLote;
  final String dataValidade;
  final double quantidade;
  final double precoCompra;
  final double? precoVenda;

  factory CompraItemRequestModel.fromEntity(CompraItemRequest entity) {
    return CompraItemRequestModel(
      produtoId: entity.produtoId,
      numeroLote: entity.numeroLote,
      dataValidade: entity.dataValidade,
      quantidade: entity.quantidade,
      precoCompra: entity.precoCompra,
      precoVenda: entity.precoVenda,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'produtoId': produtoId,
      'numeroLote': numeroLote,
      'dataValidade': dataValidade,
      'quantidade': quantidade,
      'precoCompra': precoCompra,
      if (precoVenda != null) 'precoVenda': precoVenda,
    };
  }
}

class CompraResumoModel {
  const CompraResumoModel({
    required this.id,
    required this.fornecedorId,
    required this.fornecedorNome,
    required this.status,
    required this.data,
    required this.total,
    required this.totalItens,
  });

  final String id;
  final String fornecedorId;
  final String fornecedorNome;
  final CompraStatus status;
  final DateTime data;
  final double total;
  final int totalItens;

  factory CompraResumoModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final fornecedor = json['fornecedor'];
    return CompraResumoModel(
      id: _stringValue(json, const ['id', 'compraId']),
      fornecedorId: _stringValue(json, const ['fornecedorId']),
      fornecedorNome: _stringValue(
        json,
        const ['fornecedorNome', 'nomeFornecedor'],
        fallback: fornecedor is Map<String, dynamic>
            ? _stringValue(fornecedor, const ['nome'])
            : '',
      ),
      status: CompraStatusX.fromApi(_stringValue(json, const ['status'])),
      data: _dateValue(json, const ['data', 'createdAt']),
      total: _toDouble(_dynamicValue(json, const ['total'])),
      totalItens: _toInt(_dynamicValue(json, const ['totalItens', 'itensCount'])) ??
          (items is List ? items.length : 0),
    );
  }

  CompraResumo toEntity() {
    return CompraResumo(
      id: id,
      fornecedorId: fornecedorId,
      fornecedorNome: fornecedorNome,
      status: status,
      data: data,
      total: total,
      totalItens: totalItens,
    );
  }
}

class CompraItemModel {
  const CompraItemModel({
    required this.id,
    required this.produtoId,
    required this.produtoNome,
    required this.numeroLote,
    required this.dataValidade,
    required this.quantidade,
    required this.precoCompra,
    this.precoVenda,
    required this.subtotal,
  });

  final String id;
  final String produtoId;
  final String produtoNome;
  final String numeroLote;
  final String dataValidade;
  final double quantidade;
  final double precoCompra;
  final double? precoVenda;
  final double subtotal;

  factory CompraItemModel.fromJson(Map<String, dynamic> json) {
    final produto = json['produto'];
    return CompraItemModel(
      id: _stringValue(json, const ['id', 'itemId']),
      produtoId: _stringValue(json, const ['produtoId']),
      produtoNome: _stringValue(
        json,
        const ['produtoNome', 'descricao', 'nome'],
        fallback: produto is Map<String, dynamic>
            ? _stringValue(produto, const ['nome', 'descricao'])
            : '',
      ),
      numeroLote: _stringValue(json, const ['numeroLote', 'lote']),
      dataValidade: _stringValue(json, const ['dataValidade'], fallback: ''),
      quantidade: _toDouble(_dynamicValue(json, const ['quantidade'])),
      precoCompra: _toDouble(_dynamicValue(json, const ['precoCompra', 'preco'])),
      precoVenda: _nullableDouble(_dynamicValue(json, const ['precoVenda'])),
      subtotal: _toDouble(_dynamicValue(json, const ['subtotal', 'total'])),
    );
  }

  CompraItem toEntity() {
    return CompraItem(
      id: id,
      produtoId: produtoId,
      produtoNome: produtoNome,
      numeroLote: numeroLote,
      dataValidade: dataValidade,
      quantidade: quantidade,
      precoCompra: precoCompra,
      precoVenda: precoVenda,
      subtotal: subtotal,
    );
  }
}

class CompraDetalheModel {
  const CompraDetalheModel({
    required this.id,
    required this.fornecedorId,
    required this.fornecedorNome,
    required this.status,
    required this.data,
    required this.total,
    required this.items,
  });

  final String id;
  final String fornecedorId;
  final String fornecedorNome;
  final CompraStatus status;
  final DateTime data;
  final double total;
  final List<CompraItemModel> items;

  factory CompraDetalheModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final fornecedor = json['fornecedor'];
    return CompraDetalheModel(
      id: _stringValue(json, const ['id', 'compraId']),
      fornecedorId: _stringValue(json, const ['fornecedorId']),
      fornecedorNome: _stringValue(
        json,
        const ['fornecedorNome', 'nomeFornecedor'],
        fallback: fornecedor is Map<String, dynamic>
            ? _stringValue(fornecedor, const ['nome'])
            : '',
      ),
      status: CompraStatusX.fromApi(_stringValue(json, const ['status'])),
      data: _dateValue(json, const ['data', 'createdAt']),
      total: _toDouble(_dynamicValue(json, const ['total'])),
      items: items is List
          ? items
              .whereType<Map<String, dynamic>>()
              .map(CompraItemModel.fromJson)
              .toList()
          : const <CompraItemModel>[],
    );
  }

  CompraDetalhe toEntity() {
    return CompraDetalhe(
      id: id,
      fornecedorId: fornecedorId,
      fornecedorNome: fornecedorNome,
      status: status,
      data: data,
      total: total,
      items: items.map((item) => item.toEntity()).toList(),
    );
  }
}

class CompraReceiptModel {
  const CompraReceiptModel({
    required this.message,
    required this.compraId,
    required this.total,
  });

  final String message;
  final String compraId;
  final double total;

  factory CompraReceiptModel.fromJson(Map<String, dynamic> json) {
    return CompraReceiptModel(
      message: json['message']?.toString().trim().isNotEmpty == true
          ? json['message'].toString().trim()
          : 'Compra recebida com sucesso.',
      compraId: json['compraId']?.toString() ?? '',
      total: _toDouble(json['total']),
    );
  }

  CompraReceipt toEntity() {
    return CompraReceipt(
      message: message,
      compraId: compraId,
      total: total,
    );
  }
}

String _stringValue(Map<String, dynamic> json, List<String> keys,
    {String fallback = ''}) {
  for (final key in keys) {
    if (json[key] != null) {
      final value = json[key].toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
  }
  return fallback;
}

DateTime _dateValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json[key] != null) {
      try {
        return DateTime.parse(json[key].toString());
      } catch (_) {}
    }
  }
  return DateTime.now();
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}

int? _toInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

double? _nullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  return _toDouble(value);
}

String? _nullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

dynamic _dynamicValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json[key] != null) {
      return json[key];
    }
  }
  return null;
}
