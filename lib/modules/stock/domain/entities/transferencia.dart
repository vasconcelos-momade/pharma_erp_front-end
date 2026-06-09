enum TransferenciaStatus {
  rascunho,
  confirmada,
  cancelada,
}

enum TransferenciaTipo {
  saida,
  entrada,
}

extension TransferenciaStatusX on TransferenciaStatus {
  String get apiValue {
    switch (this) {
      case TransferenciaStatus.rascunho:
        return 'RASCUNHO';
      case TransferenciaStatus.confirmada:
        return 'CONFIRMADA';
      case TransferenciaStatus.cancelada:
        return 'CANCELADA';
    }
  }

  String get label {
    switch (this) {
      case TransferenciaStatus.rascunho:
        return 'Rascunho';
      case TransferenciaStatus.confirmada:
        return 'Confirmada';
      case TransferenciaStatus.cancelada:
        return 'Cancelada';
    }
  }

  bool get isEditable => this == TransferenciaStatus.rascunho;

  static TransferenciaStatus fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'CONFIRMADA':
        return TransferenciaStatus.confirmada;
      case 'CANCELADA':
        return TransferenciaStatus.cancelada;
      case 'RASCUNHO':
      default:
        return TransferenciaStatus.rascunho;
    }
  }
}

extension TransferenciaTipoX on TransferenciaTipo {
  String get apiValue {
    switch (this) {
      case TransferenciaTipo.saida:
        return 'SAIDA';
      case TransferenciaTipo.entrada:
        return 'ENTRADA';
    }
  }

  String get label {
    switch (this) {
      case TransferenciaTipo.saida:
        return 'Saida';
      case TransferenciaTipo.entrada:
        return 'Entrada';
    }
  }

  static TransferenciaTipo fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'ENTRADA':
        return TransferenciaTipo.entrada;
      case 'SAIDA':
      default:
        return TransferenciaTipo.saida;
    }
  }
}

class CriarTransferenciaRequest {
  const CriarTransferenciaRequest({
    required this.numeroDocumento,
    required this.origem,
    required this.destino,
    this.tipo = TransferenciaTipo.saida,
    this.observacao,
  });

  final String numeroDocumento;
  final String origem;
  final String destino;
  final TransferenciaTipo tipo;
  final String? observacao;
}

class TransferenciaItemRequest {
  const TransferenciaItemRequest({
    required this.produtoId,
    required this.quantidade,
    this.loteId,
  });

  final String produtoId;
  final String? loteId;
  final double quantidade;
}

class TransferenciaResumo {
  const TransferenciaResumo({
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
}

class TransferenciaUsuario {
  const TransferenciaUsuario({
    required this.id,
    required this.nome,
    this.email,
  });

  final String id;
  final String nome;
  final String? email;
}

class TransferenciaLote {
  const TransferenciaLote({
    required this.id,
    required this.numeroLote,
    this.dataValidade,
  });

  final String id;
  final String numeroLote;
  final DateTime? dataValidade;
}

class TransferenciaItem {
  const TransferenciaItem({
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
  final TransferenciaLote? lote;
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

class TransferenciaDetalhe {
  const TransferenciaDetalhe({
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
  final List<TransferenciaItem> itens;
  final TransferenciaUsuario? user;
  final TransferenciaUsuario? confirmedBy;

  int get totalItens => itens.length;

  double get quantidadeTotal =>
      itens.fold<double>(0, (sum, item) => sum + item.quantidade);
}

class TransferenciaOperacaoResultado {
  const TransferenciaOperacaoResultado({
    required this.message,
    required this.transferenciaId,
    this.status,
  });

  final String message;
  final String transferenciaId;
  final TransferenciaStatus? status;
}
