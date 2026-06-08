enum CompraStatus {
  pendente,
  recebida,
  cancelada,
}

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

extension CompraStatusX on CompraStatus {
  String get apiValue {
    switch (this) {
      case CompraStatus.pendente:
        return 'PENDENTE';
      case CompraStatus.recebida:
        return 'RECEBIDA';
      case CompraStatus.cancelada:
        return 'CANCELADA';
    }
  }

  String get label {
    switch (this) {
      case CompraStatus.pendente:
        return 'Pendente';
      case CompraStatus.recebida:
        return 'Finalizada';
      case CompraStatus.cancelada:
        return 'Cancelada';
    }
  }

  bool get isEditable => this == CompraStatus.pendente;

  static CompraStatus fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'RECEBIDA':
      case 'FINALIZADA':
        return CompraStatus.recebida;
      case 'CANCELADA':
        return CompraStatus.cancelada;
      case 'PENDENTE':
      default:
        return CompraStatus.pendente;
    }
  }
}

class CriarCompraPendenteRequest {
  const CriarCompraPendenteRequest({
    required this.fornecedorId,
    required this.numeroDocumento,
  });

  final String fornecedorId;
  final String numeroDocumento;
}

class CompraItemRequest {
  const CompraItemRequest({
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
}

class CompraResumo {
  const CompraResumo({
    required this.id,
    required this.numeroDocumento,
    required this.fornecedorId,
    required this.fornecedorNome,
    required this.status,
    required this.data,
    required this.total,
    required this.totalItens,
  });

  final String id;
  final String numeroDocumento;
  final String fornecedorId;
  final String fornecedorNome;
  final CompraStatus status;
  final DateTime data;
  final double total;
  final int totalItens;
}

class CompraItem {
  const CompraItem({
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
}

class CompraDetalhe {
  const CompraDetalhe({
    required this.id,
    required this.numeroDocumento,
    required this.fornecedorId,
    required this.fornecedorNome,
    required this.status,
    required this.data,
    required this.total,
    required this.items,
  });

  final String id;
  final String numeroDocumento;
  final String fornecedorId;
  final String fornecedorNome;
  final CompraStatus status;
  final DateTime data;
  final double total;
  final List<CompraItem> items;

  int get totalItens => items.length;

  CompraDetalhe copyWith({
    String? id,
    String? numeroDocumento,
    String? fornecedorId,
    String? fornecedorNome,
    CompraStatus? status,
    DateTime? data,
    double? total,
    List<CompraItem>? items,
  }) {
    return CompraDetalhe(
      id: id ?? this.id,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      fornecedorId: fornecedorId ?? this.fornecedorId,
      fornecedorNome: fornecedorNome ?? this.fornecedorNome,
      status: status ?? this.status,
      data: data ?? this.data,
      total: total ?? this.total,
      items: items ?? this.items,
    );
  }
}

class CompraReceipt {
  const CompraReceipt({
    required this.message,
    required this.compraId,
    required this.total,
  });

  final String message;
  final String compraId;
  final double total;
}
