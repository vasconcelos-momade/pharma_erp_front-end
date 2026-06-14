enum RequisicaoStatus {
  pendente,
  aprovada,
  rejeitada,
  concluida,
  cancelada,
}

enum RequisicaoTipo {
  compra,
  entrada,
  saida,
}

extension RequisicaoStatusX on RequisicaoStatus {
  String get apiValue {
    switch (this) {
      case RequisicaoStatus.pendente:
        return 'PENDENTE';
      case RequisicaoStatus.aprovada:
        return 'APROVADA';
      case RequisicaoStatus.rejeitada:
        return 'REJEITADA';
      case RequisicaoStatus.concluida:
        return 'CONCLUIDA';
      case RequisicaoStatus.cancelada:
        return 'CANCELADA';
    }
  }

  String get label {
    switch (this) {
      case RequisicaoStatus.pendente:
        return 'Pendente';
      case RequisicaoStatus.aprovada:
        return 'Aprovada';
      case RequisicaoStatus.rejeitada:
        return 'Rejeitada';
      case RequisicaoStatus.concluida:
        return 'Concluida';
      case RequisicaoStatus.cancelada:
        return 'Cancelada';
    }
  }

  bool get isEditable => this == RequisicaoStatus.pendente;
  bool get isHistory => this != RequisicaoStatus.pendente;
  bool get isPositive =>
      this == RequisicaoStatus.aprovada || this == RequisicaoStatus.concluida;

  static RequisicaoStatus fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'APROVADA':
        return RequisicaoStatus.aprovada;
      case 'REJEITADA':
        return RequisicaoStatus.rejeitada;
      case 'CONCLUIDA':
      case 'CONFIRMADA':
        return RequisicaoStatus.concluida;
      case 'CANCELADA':
        return RequisicaoStatus.cancelada;
      case 'PENDENTE':
      case 'RASCUNHO':
      default:
        return RequisicaoStatus.pendente;
    }
  }
}

extension RequisicaoTipoX on RequisicaoTipo {
  String get apiValue {
    switch (this) {
      case RequisicaoTipo.compra:
        return 'COMPRA';
      case RequisicaoTipo.entrada:
        return 'ENTRADA';
      case RequisicaoTipo.saida:
        return 'SAIDA';
    }
  }

  String get label {
    switch (this) {
      case RequisicaoTipo.compra:
        return 'Compra';
      case RequisicaoTipo.entrada:
        return 'Entrada';
      case RequisicaoTipo.saida:
        return 'Saida';
    }
  }

  bool get requiresOrigem => this == RequisicaoTipo.entrada;
  bool get requiresDestino => this == RequisicaoTipo.saida;
  bool get isOutbound => this == RequisicaoTipo.saida;
  bool get isCompra => this == RequisicaoTipo.compra;

  static RequisicaoTipo fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'COMPRA':
        return RequisicaoTipo.compra;
      case 'ENTRADA':
        return RequisicaoTipo.entrada;
      case 'TRANSFERENCIA':
      case 'SAIDA':
      default:
        return RequisicaoTipo.saida;
    }
  }
}

class CriarRequisicaoRequest {
  const CriarRequisicaoRequest({
    required this.numeroDocumento,
    this.fornecedorId,
    this.origem,
    this.destino,
    this.tipo = RequisicaoTipo.saida,
    this.observacao,
  });

  final String numeroDocumento;
  final String? fornecedorId;
  final String? origem;
  final String? destino;
  final RequisicaoTipo tipo;
  final String? observacao;
}

class AtualizarRequisicaoRequest {
  const AtualizarRequisicaoRequest({
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
}

class RequisicaoItemRequest {
  const RequisicaoItemRequest({
    required this.produtoId,
    required this.quantidadeSolicitada,
    this.loteId,
    this.numeroLote,
    this.dataValidade,
    this.precoCompra,
    this.precoVenda,
  });

  final String produtoId;
  final String? loteId;
  final double quantidadeSolicitada;
  final String? numeroLote;
  final String? dataValidade;
  final double? precoCompra;
  final double? precoVenda;
}

class RequisicaoResumo {
  const RequisicaoResumo({
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
}

class RequisicaoUsuario {
  const RequisicaoUsuario({
    required this.id,
    required this.nome,
    this.email,
  });

  final String id;
  final String nome;
  final String? email;
}

class RequisicaoLote {
  const RequisicaoLote({
    required this.id,
    required this.numeroLote,
    this.dataValidade,
  });

  final String id;
  final String numeroLote;
  final DateTime? dataValidade;
}

class RequisicaoItem {
  const RequisicaoItem({
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
  final RequisicaoLote? lote;
  final String? numeroLote;
  final DateTime? dataValidade;
  final double? precoCompra;
  final double? precoVenda;
  final double? subtotal;

  double get quantidade => quantidadeSolicitada;
}

class ProdutoLoteDisponivel {
  const ProdutoLoteDisponivel({
    required this.id,
    required this.numeroLote,
    required this.dataValidade,
    required this.quantidadeAtual,
  });

  final String id;
  final String numeroLote;
  final DateTime dataValidade;
  final double quantidadeAtual;
}

class RequisicaoDetalhe {
  const RequisicaoDetalhe({
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
  final List<RequisicaoItem> itens;
  final RequisicaoUsuario? user;
  final RequisicaoUsuario? confirmedBy;

  List<RequisicaoItem> get items => itens;

  int get totalItens => itens.length;

  double get quantidadeTotal =>
      itens.fold<double>(0, (sum, item) => sum + item.quantidadeSolicitada);

  bool get requiresStockValidation => tipo == RequisicaoTipo.saida;
}

class CriarLoteRequest {
  const CriarLoteRequest({
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
}

class CriarLoteResult {
  const CriarLoteResult({
    required this.message,
    required this.loteId,
    required this.lote,
  });

  final String message;
  final String loteId;
  final dynamic lote;
}

class RequisicaoOperacaoResultado {
  const RequisicaoOperacaoResultado({
    required this.message,
    required this.requisicaoId,
    this.status,
  });

  final String message;
  final String requisicaoId;
  final RequisicaoStatus? status;
}
