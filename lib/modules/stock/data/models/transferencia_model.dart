import '../../domain/entities/transferencia.dart';

class CriarTransferenciaRequestModel {
  const CriarTransferenciaRequestModel({
    required this.numeroDocumento,
    required this.origem,
    required this.destino,
    required this.tipo,
    this.observacao,
  });

  final String numeroDocumento;
  final String origem;
  final String destino;
  final String tipo;
  final String? observacao;

  factory CriarTransferenciaRequestModel.fromEntity(
    CriarTransferenciaRequest entity,
  ) {
    return CriarTransferenciaRequestModel(
      numeroDocumento: entity.numeroDocumento,
      origem: entity.origem,
      destino: entity.destino,
      tipo: entity.tipo.apiValue,
      observacao: entity.observacao,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'numeroDocumento': numeroDocumento,
      'origem': origem,
      'destino': destino,
      'tipo': tipo,
      if (observacao != null && observacao!.trim().isNotEmpty)
        'observacao': observacao,
    };
  }
}

class TransferenciaItemRequestModel {
  const TransferenciaItemRequestModel({
    required this.produtoId,
    required this.quantidade,
    this.loteId,
  });

  final String produtoId;
  final double quantidade;
  final String? loteId;

  factory TransferenciaItemRequestModel.fromEntity(
    TransferenciaItemRequest entity,
  ) {
    return TransferenciaItemRequestModel(
      produtoId: entity.produtoId,
      quantidade: entity.quantidade,
      loteId: entity.loteId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'produtoId': produtoId,
      'quantidade': quantidade,
      if (loteId != null && loteId!.trim().isNotEmpty) 'loteId': loteId,
    };
  }
}

class TransferenciaResumoModel {
  const TransferenciaResumoModel({
    required this.id,
    required this.numeroDocumento,
    required this.origem,
    required this.destino,
    required this.tipo,
    required this.status,
    this.observacao,
    required this.totalItens,
    required this.quantidadeTotal,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String numeroDocumento;
  final String origem;
  final String destino;
  final TransferenciaTipo tipo;
  final TransferenciaStatus status;
  final String? observacao;
  final int totalItens;
  final double quantidadeTotal;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TransferenciaResumoModel.fromJson(Map<String, dynamic> json) {
    return TransferenciaResumoModel(
      id: _stringValue(json, const ['id', 'transferenciaId']),
      numeroDocumento: _stringValue(json, const ['numeroDocumento']),
      origem: _stringValue(json, const ['origem']),
      destino: _stringValue(json, const ['destino']),
      tipo: TransferenciaTipoX.fromApi(
        _stringValue(json, const ['tipo'], fallback: 'SAIDA'),
      ),
      status: TransferenciaStatusX.fromApi(
        _stringValue(json, const ['status'], fallback: 'RASCUNHO'),
      ),
      observacao: _nullableString(json['observacao']),
      totalItens: _toInt(json['totalItens']) ?? 0,
      quantidadeTotal: _toDouble(json['quantidadeTotal']),
      createdAt: _dateValue(json, const ['createdAt']),
      updatedAt: _dateValue(json, const ['updatedAt', 'createdAt']),
    );
  }

  TransferenciaResumo toEntity() {
    return TransferenciaResumo(
      id: id,
      numeroDocumento: numeroDocumento,
      origem: origem,
      destino: destino,
      tipo: tipo,
      status: status,
      observacao: observacao,
      totalItens: totalItens,
      quantidadeTotal: quantidadeTotal,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class TransferenciaUsuarioModel {
  const TransferenciaUsuarioModel({
    required this.id,
    required this.nome,
    this.email,
  });

  final String id;
  final String nome;
  final String? email;

  factory TransferenciaUsuarioModel.fromJson(Map<String, dynamic> json) {
    return TransferenciaUsuarioModel(
      id: _stringValue(json, const ['id']),
      nome: _stringValue(json, const ['name', 'nome'], fallback: 'Operador'),
      email: _nullableString(json['email']),
    );
  }

  TransferenciaUsuario toEntity() {
    return TransferenciaUsuario(id: id, nome: nome, email: email);
  }
}

class TransferenciaLoteModel {
  const TransferenciaLoteModel({
    required this.id,
    required this.numeroLote,
    this.dataValidade,
  });

  final String id;
  final String numeroLote;
  final DateTime? dataValidade;

  factory TransferenciaLoteModel.fromJson(Map<String, dynamic> json) {
    return TransferenciaLoteModel(
      id: _stringValue(json, const ['id']),
      numeroLote: _stringValue(json, const ['numeroLote'], fallback: 'Lote'),
      dataValidade: _nullableDate(json['dataValidade']),
    );
  }

  TransferenciaLote toEntity() {
    return TransferenciaLote(
      id: id,
      numeroLote: numeroLote,
      dataValidade: dataValidade,
    );
  }
}

class TransferenciaItemModel {
  const TransferenciaItemModel({
    required this.id,
    required this.quantidade,
    required this.produtoId,
    required this.produtoNome,
    this.lote,
  });

  final String id;
  final double quantidade;
  final String produtoId;
  final String produtoNome;
  final TransferenciaLoteModel? lote;

  factory TransferenciaItemModel.fromJson(Map<String, dynamic> json) {
    final produto = json['produto'];
    final lote = json['lote'];
    return TransferenciaItemModel(
      id: _stringValue(json, const ['id', 'itemId']),
      quantidade: _toDouble(json['quantidade']),
      produtoId: _stringValue(
        produto is Map<String, dynamic> ? produto : json,
        const ['id', 'produtoId'],
      ),
      produtoNome: produto is Map<String, dynamic>
          ? _stringValue(produto, const ['nome'], fallback: 'Produto')
          : _stringValue(json, const ['produtoNome'], fallback: 'Produto'),
      lote: lote is Map<String, dynamic>
          ? TransferenciaLoteModel.fromJson(lote)
          : null,
    );
  }

  TransferenciaItem toEntity() {
    return TransferenciaItem(
      id: id,
      quantidade: quantidade,
      produtoId: produtoId,
      produtoNome: produtoNome,
      lote: lote?.toEntity(),
    );
  }
}

class ProdutoLoteDisponivelModel {
  const ProdutoLoteDisponivelModel({
    required this.id,
    required this.numeroLote,
    required this.dataValidade,
    required this.quantidadeAtual,
  });

  final String id;
  final String numeroLote;
  final DateTime dataValidade;
  final double quantidadeAtual;

  factory ProdutoLoteDisponivelModel.fromJson(Map<String, dynamic> json) {
    return ProdutoLoteDisponivelModel(
      id: _stringValue(json, const ['id']),
      numeroLote: _stringValue(json, const ['numeroLote'], fallback: 'Lote'),
      dataValidade: _dateValue(json, const ['dataValidade']),
      quantidadeAtual: _toDouble(json['quantidadeAtual']),
    );
  }
}

class TransferenciaDetalheModel {
  const TransferenciaDetalheModel({
    required this.id,
    required this.numeroDocumento,
    required this.origem,
    required this.destino,
    required this.tipo,
    required this.status,
    this.observacao,
    this.confirmedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.itens,
    this.user,
    this.confirmedBy,
  });

  final String id;
  final String numeroDocumento;
  final String origem;
  final String destino;
  final TransferenciaTipo tipo;
  final TransferenciaStatus status;
  final String? observacao;
  final DateTime? confirmedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TransferenciaItemModel> itens;
  final TransferenciaUsuarioModel? user;
  final TransferenciaUsuarioModel? confirmedBy;

  factory TransferenciaDetalheModel.fromJson(Map<String, dynamic> json) {
    final itens = json['itens'];
    final user = json['user'];
    final confirmedBy = json['confirmedBy'];
    return TransferenciaDetalheModel(
      id: _stringValue(json, const ['id', 'transferenciaId']),
      numeroDocumento: _stringValue(json, const ['numeroDocumento']),
      origem: _stringValue(json, const ['origem']),
      destino: _stringValue(json, const ['destino']),
      tipo: TransferenciaTipoX.fromApi(
        _stringValue(json, const ['tipo'], fallback: 'SAIDA'),
      ),
      status: TransferenciaStatusX.fromApi(
        _stringValue(json, const ['status'], fallback: 'RASCUNHO'),
      ),
      observacao: _nullableString(json['observacao']),
      confirmedAt: _nullableDate(json['confirmedAt']),
      createdAt: _dateValue(json, const ['createdAt']),
      updatedAt: _dateValue(json, const ['updatedAt', 'createdAt']),
      itens: itens is List
          ? itens
              .whereType<Map<String, dynamic>>()
              .map(TransferenciaItemModel.fromJson)
              .toList()
          : const <TransferenciaItemModel>[],
      user: user is Map<String, dynamic>
          ? TransferenciaUsuarioModel.fromJson(user)
          : null,
      confirmedBy: confirmedBy is Map<String, dynamic>
          ? TransferenciaUsuarioModel.fromJson(confirmedBy)
          : null,
    );
  }

  TransferenciaDetalhe toEntity() {
    return TransferenciaDetalhe(
      id: id,
      numeroDocumento: numeroDocumento,
      origem: origem,
      destino: destino,
      tipo: tipo,
      status: status,
      observacao: observacao,
      confirmedAt: confirmedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      itens: itens.map((item) => item.toEntity()).toList(),
      user: user?.toEntity(),
      confirmedBy: confirmedBy?.toEntity(),
    );
  }
}

class TransferenciaOperacaoResultadoModel {
  const TransferenciaOperacaoResultadoModel({
    required this.message,
    required this.transferenciaId,
    this.status,
  });

  final String message;
  final String transferenciaId;
  final TransferenciaStatus? status;

  factory TransferenciaOperacaoResultadoModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final statusValue = _nullableString(json['status']);
    return TransferenciaOperacaoResultadoModel(
      message: _stringValue(
        json,
        const ['message'],
        fallback: 'Operação concluída com sucesso.',
      ),
      transferenciaId: _stringValue(json, const ['transferenciaId', 'id']),
      status: statusValue == null
          ? null
          : TransferenciaStatusX.fromApi(statusValue),
    );
  }

  TransferenciaOperacaoResultado toEntity() {
    return TransferenciaOperacaoResultado(
      message: message,
      transferenciaId: transferenciaId,
      status: status,
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

String? _nullableString(dynamic value) {
  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime _dateValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final parsed = _nullableDate(json[key]);
    if (parsed != null) {
      return parsed;
    }
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _nullableDate(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
