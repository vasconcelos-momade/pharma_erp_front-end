import '../../domain/entities/requisicao.dart';

class CriarRequisicaoRequestModel {
  const CriarRequisicaoRequestModel({
    required this.numeroDocumento,
    this.fornecedorId,
    this.origem,
    this.destino,
    required this.tipo,
    this.observacao,
  });

  final String numeroDocumento;
  final String? fornecedorId;
  final String? origem;
  final String? destino;
  final String tipo;
  final String? observacao;

  factory CriarRequisicaoRequestModel.fromEntity(
    CriarRequisicaoRequest entity,
  ) {
    return CriarRequisicaoRequestModel(
      numeroDocumento: entity.numeroDocumento,
      fornecedorId: entity.fornecedorId,
      origem: entity.origem,
      destino: entity.destino,
      tipo: entity.tipo.apiValue,
      observacao: entity.observacao,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'numeroDocumento': numeroDocumento,
      if (fornecedorId != null && fornecedorId!.trim().isNotEmpty)
        'fornecedorId': fornecedorId,
      if (origem != null && origem!.trim().isNotEmpty) 'origem': origem,
      if (destino != null && destino!.trim().isNotEmpty) 'destino': destino,
      'tipo': tipo,
      if (observacao != null && observacao!.trim().isNotEmpty)
        'observacao': observacao,
    };
  }
}

class AtualizarRequisicaoRequestModel {
  const AtualizarRequisicaoRequestModel({
    this.numeroDocumento,
    this.fornecedorId,
    this.origem,
    this.destino,
    this.observacao,
  });

  final String? numeroDocumento;
  final String? fornecedorId;
  final String? origem;
  final String? destino;
  final String? observacao;

  factory AtualizarRequisicaoRequestModel.fromEntity(
    AtualizarRequisicaoRequest entity,
  ) {
    return AtualizarRequisicaoRequestModel(
      numeroDocumento: entity.numeroDocumento,
      fornecedorId: entity.fornecedorId,
      origem: entity.origem,
      destino: entity.destino,
      observacao: entity.observacao,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (numeroDocumento != null && numeroDocumento!.trim().isNotEmpty)
        'numeroDocumento': numeroDocumento,
      if (fornecedorId != null) 'fornecedorId': fornecedorId,
      if (origem != null) 'origem': origem,
      if (destino != null) 'destino': destino,
      if (observacao != null) 'observacao': observacao,
    };
  }
}

class RequisicaoItemRequestModel {
  const RequisicaoItemRequestModel({
    required this.produtoId,
    required this.quantidadeSolicitada,
    this.loteId,
    this.numeroLote,
    this.dataValidade,
    this.precoCompra,
    this.precoVenda,
  });

  final String produtoId;
  final double quantidadeSolicitada;
  final String? loteId;
  final String? numeroLote;
  final String? dataValidade;
  final double? precoCompra;
  final double? precoVenda;

  factory RequisicaoItemRequestModel.fromEntity(
    RequisicaoItemRequest entity,
  ) {
    return RequisicaoItemRequestModel(
      produtoId: entity.produtoId,
      quantidadeSolicitada: entity.quantidadeSolicitada,
      loteId: entity.loteId,
      numeroLote: entity.numeroLote,
      dataValidade: entity.dataValidade,
      precoCompra: entity.precoCompra,
      precoVenda: entity.precoVenda,
    );
  }

  Map<String, dynamic> toJson() {
    if (numeroLote != null && numeroLote!.trim().isNotEmpty) {
      return <String, dynamic>{
        'produtoId': produtoId,
        'numeroLote': numeroLote,
        'dataValidade': dataValidade,
        'quantidadeSolicitada': quantidadeSolicitada,
        'precoCompra': precoCompra,
        if (precoVenda != null) 'precoVenda': precoVenda,
      };
    }

    return <String, dynamic>{
      'produtoId': produtoId,
      'quantidadeSolicitada': quantidadeSolicitada,
      if (loteId != null && loteId!.trim().isNotEmpty) 'loteId': loteId,
    };
  }
}

class RequisicaoResumoModel {
  const RequisicaoResumoModel({
    required this.id,
    required this.numeroDocumento,
    required this.origem,
    required this.destino,
    required this.tipo,
    required this.status,
    this.observacao,
    this.fornecedorId,
    this.fornecedorNome,
    this.total,
    required this.totalItens,
    required this.quantidadeTotal,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String numeroDocumento;
  final String? origem;
  final String? destino;
  final RequisicaoTipo tipo;
  final RequisicaoStatus status;
  final String? observacao;
  final String? fornecedorId;
  final String? fornecedorNome;
  final double? total;
  final int totalItens;
  final double quantidadeTotal;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RequisicaoResumoModel.fromJson(Map<String, dynamic> json) {
    return RequisicaoResumoModel(
      id: _stringValue(json, const ['id', 'requisicaoId', 'transferenciaId']),
      numeroDocumento: _stringValue(json, const ['numeroDocumento']),
      origem: _nullableString(json['origem']),
      destino: _nullableString(json['destino']),
      tipo: RequisicaoTipoX.fromApi(
        _stringValue(json, const ['tipo'], fallback: 'SAIDA'),
      ),
      status: RequisicaoStatusX.fromApi(
        _stringValue(json, const ['status'], fallback: 'PENDENTE'),
      ),
      observacao: _nullableString(json['observacao']),
      fornecedorId: _nullableString(json['fornecedorId']),
      fornecedorNome: _nullableString(json['fornecedorNome']),
      total: json['total'] == null ? null : _toDouble(json['total']),
      totalItens: _toInt(json['totalItens']) ?? 0,
      quantidadeTotal: _toDouble(json['quantidadeTotal']),
      createdAt: _dateValue(json, const ['createdAt', 'data']),
      updatedAt: _dateValue(json, const ['updatedAt', 'createdAt', 'data']),
    );
  }

  RequisicaoResumo toEntity() {
    return RequisicaoResumo(
      id: id,
      numeroDocumento: numeroDocumento,
      origem: origem,
      destino: destino,
      tipo: tipo,
      status: status,
      observacao: observacao,
      fornecedorId: fornecedorId,
      fornecedorNome: fornecedorNome,
      total: total,
      totalItens: totalItens,
      quantidadeTotal: quantidadeTotal,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class RequisicaoUsuarioModel {
  const RequisicaoUsuarioModel({
    required this.id,
    required this.nome,
    this.email,
  });

  final String id;
  final String nome;
  final String? email;

  factory RequisicaoUsuarioModel.fromJson(Map<String, dynamic> json) {
    return RequisicaoUsuarioModel(
      id: _stringValue(json, const ['id']),
      nome: _stringValue(json, const ['name', 'nome'], fallback: 'Operador'),
      email: _nullableString(json['email']),
    );
  }

  RequisicaoUsuario toEntity() {
    return RequisicaoUsuario(id: id, nome: nome, email: email);
  }
}

class RequisicaoLoteModel {
  const RequisicaoLoteModel({
    required this.id,
    required this.numeroLote,
    this.dataValidade,
  });

  final String id;
  final String numeroLote;
  final DateTime? dataValidade;

  factory RequisicaoLoteModel.fromJson(Map<String, dynamic> json) {
    return RequisicaoLoteModel(
      id: _stringValue(json, const ['id']),
      numeroLote: _stringValue(json, const ['numeroLote'], fallback: 'Lote'),
      dataValidade: _nullableDate(json['dataValidade']),
    );
  }

  RequisicaoLote toEntity() {
    return RequisicaoLote(
      id: id,
      numeroLote: numeroLote,
      dataValidade: dataValidade,
    );
  }
}

class RequisicaoItemModel {
  const RequisicaoItemModel({
    required this.id,
    required this.quantidadeSolicitada,
    required this.produtoId,
    required this.produtoNome,
    this.lote,
    this.numeroLote,
    this.dataValidade,
    this.precoCompra,
    this.precoVenda,
    this.subtotal,
  });

  final String id;
  final double quantidadeSolicitada;
  final String produtoId;
  final String produtoNome;
  final RequisicaoLoteModel? lote;
  final String? numeroLote;
  final DateTime? dataValidade;
  final double? precoCompra;
  final double? precoVenda;
  final double? subtotal;

  factory RequisicaoItemModel.fromJson(Map<String, dynamic> json) {
    final produto = json['produto'];
    final lote = json['lote'];
    return RequisicaoItemModel(
      id: _stringValue(json, const ['id', 'itemId']),
      quantidadeSolicitada: _toDouble(
        json['quantidadeSolicitada'] ?? json['quantidade'],
      ),
      produtoId: _stringValue(
        produto is Map<String, dynamic> ? produto : json,
        const ['id', 'produtoId'],
      ),
      produtoNome: produto is Map<String, dynamic>
          ? _stringValue(produto, const ['nome'], fallback: 'Produto')
          : _stringValue(json, const ['produtoNome'], fallback: 'Produto'),
      lote: lote is Map<String, dynamic>
          ? RequisicaoLoteModel.fromJson(lote)
          : null,
      numeroLote: _nullableString(json['numeroLote']),
      dataValidade: _nullableDate(json['dataValidade']),
      precoCompra:
          json['precoCompra'] == null ? null : _toDouble(json['precoCompra']),
      precoVenda:
          json['precoVenda'] == null ? null : _toDouble(json['precoVenda']),
      subtotal: json['subtotal'] == null ? null : _toDouble(json['subtotal']),
    );
  }

  RequisicaoItem toEntity() {
    return RequisicaoItem(
      id: id,
      quantidadeSolicitada: quantidadeSolicitada,
      produtoId: produtoId,
      produtoNome: produtoNome,
      lote: lote?.toEntity(),
      numeroLote: numeroLote,
      dataValidade: dataValidade,
      precoCompra: precoCompra,
      precoVenda: precoVenda,
      subtotal: subtotal,
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

class RequisicaoDetalheModel {
  const RequisicaoDetalheModel({
    required this.id,
    required this.numeroDocumento,
    required this.origem,
    required this.destino,
    required this.tipo,
    required this.status,
    this.observacao,
    this.fornecedorId,
    this.fornecedorNome,
    this.total,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.itens,
    this.user,
    this.confirmedBy,
  });

  final String id;
  final String numeroDocumento;
  final String? origem;
  final String? destino;
  final RequisicaoTipo tipo;
  final RequisicaoStatus status;
  final String? observacao;
  final String? fornecedorId;
  final String? fornecedorNome;
  final double? total;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RequisicaoItemModel> itens;
  final RequisicaoUsuarioModel? user;
  final RequisicaoUsuarioModel? confirmedBy;

  factory RequisicaoDetalheModel.fromJson(Map<String, dynamic> json) {
    final rawItens = json['itens'] ?? json['items'];
    final user = json['user'];
    final confirmedBy = json['confirmedBy'];
    return RequisicaoDetalheModel(
      id: _stringValue(json, const ['id', 'requisicaoId', 'transferenciaId']),
      numeroDocumento: _stringValue(json, const ['numeroDocumento']),
      origem: _nullableString(json['origem']),
      destino: _nullableString(json['destino']),
      tipo: RequisicaoTipoX.fromApi(
        _stringValue(json, const ['tipo'], fallback: 'SAIDA'),
      ),
      status: RequisicaoStatusX.fromApi(
        _stringValue(json, const ['status'], fallback: 'PENDENTE'),
      ),
      observacao: _nullableString(json['observacao']),
      fornecedorId: _nullableString(json['fornecedorId']),
      fornecedorNome: _nullableString(json['fornecedorNome']),
      total: json['total'] == null ? null : _toDouble(json['total']),
      approvedAt: _nullableDate(
        _dynamicValue(json, const ['approvedAt', 'confirmedAt']),
      ),
      createdAt: _dateValue(json, const ['createdAt', 'data']),
      updatedAt: _dateValue(json, const ['updatedAt', 'createdAt', 'data']),
      itens: rawItens is List
          ? rawItens
              .whereType<Map<String, dynamic>>()
              .map(RequisicaoItemModel.fromJson)
              .toList()
          : const <RequisicaoItemModel>[],
      user: user is Map<String, dynamic>
          ? RequisicaoUsuarioModel.fromJson(user)
          : null,
      confirmedBy: confirmedBy is Map<String, dynamic>
          ? RequisicaoUsuarioModel.fromJson(confirmedBy)
          : null,
    );
  }

  RequisicaoDetalhe toEntity() {
    return RequisicaoDetalhe(
      id: id,
      numeroDocumento: numeroDocumento,
      origem: origem,
      destino: destino,
      tipo: tipo,
      status: status,
      observacao: observacao,
      fornecedorId: fornecedorId,
      fornecedorNome: fornecedorNome,
      total: total,
      approvedAt: approvedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      itens: itens.map((item) => item.toEntity()).toList(),
      user: user?.toEntity(),
      confirmedBy: confirmedBy?.toEntity(),
    );
  }
}

class CriarLoteRequestModel {
  const CriarLoteRequestModel({
    required this.produtoId,
    required this.fornecedorId,
    required this.numeroLote,
    required this.dataValidade,
    this.precoCompra,
  });

  final String produtoId;
  final String fornecedorId;
  final String numeroLote;
  final DateTime dataValidade;
  final double? precoCompra;

  factory CriarLoteRequestModel.fromEntity(CriarLoteRequest entity) {
    return CriarLoteRequestModel(
      produtoId: entity.produtoId,
      fornecedorId: entity.fornecedorId,
      numeroLote: entity.numeroLote,
      dataValidade: entity.dataValidade,
      precoCompra: entity.precoCompra,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'produtoId': produtoId,
      'fornecedorId': fornecedorId,
      'numeroLote': numeroLote,
      'dataValidade': dataValidade.toIso8601String(),
      if (precoCompra != null) 'precoCompra': precoCompra,
    };
  }
}

class CriarLoteResultModel {
  const CriarLoteResultModel({
    required this.message,
    required this.loteId,
    required this.lote,
  });

  final String message;
  final String loteId;
  final dynamic lote;

  factory CriarLoteResultModel.fromJson(Map<String, dynamic> json) {
    return CriarLoteResultModel(
      message: _stringValue(json, const ['message'], fallback: 'Lote criado com sucesso.'),
      loteId: _stringValue(json, const ['loteId', 'id']),
      lote: json['lote'],
    );
  }

  CriarLoteResult toEntity() {
    return CriarLoteResult(
      message: message,
      loteId: loteId,
      lote: lote,
    );
  }
}

class RequisicaoOperacaoResultadoModel {
  const RequisicaoOperacaoResultadoModel({
    required this.message,
    required this.requisicaoId,
    this.status,
  });

  final String message;
  final String requisicaoId;
  final RequisicaoStatus? status;

  factory RequisicaoOperacaoResultadoModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final statusValue = _nullableString(json['status']);
    return RequisicaoOperacaoResultadoModel(
      message: _stringValue(
        json,
        const ['message'],
        fallback: 'Operacao concluida com sucesso.',
      ),
      requisicaoId: _stringValue(
        json,
        const ['requisicaoId', 'transferenciaId', 'id'],
      ),
      status: statusValue == null
          ? null
          : RequisicaoStatusX.fromApi(statusValue),
    );
  }

  RequisicaoOperacaoResultado toEntity() {
    return RequisicaoOperacaoResultado(
      message: message,
      requisicaoId: requisicaoId,
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

dynamic _dynamicValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}
