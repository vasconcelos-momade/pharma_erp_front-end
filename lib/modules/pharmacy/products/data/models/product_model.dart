import '../../domain/entities/categoria_produto.dart';
import '../../domain/entities/product_tax_rule.dart';

class ProductModel {
  final String id;
  final String nome;
  final String? substanciaActiva;
  final String? dosagem;
  final String? forma;
  final String? apresentacao;
  final bool ativo;
  final String? barcode;
  final CategoriaProduto categoria;
  final String tipoDispensacao;
  final bool requiresPrescription;
  final bool requiresDoubleCheck;
  final bool requiresPsychotropicBook;
  final double precoVenda;
  final double estoqueAtual;
  final double estoqueMinimo;
  final String? lote;
  final DateTime? dataValidade;
  final DateTime? createdAt;
  final ProductTaxRule? taxRule;

  ProductModel({
    required this.id,
    required this.nome,
    this.substanciaActiva,
    this.dosagem,
    this.forma,
    this.apresentacao,
    required this.ativo,
    this.barcode,
    this.categoria = CategoriaProduto.medicamento,
    required this.tipoDispensacao,
    required this.requiresPrescription,
    required this.requiresDoubleCheck,
    required this.requiresPsychotropicBook,
    required this.precoVenda,
    required this.estoqueAtual,
    required this.estoqueMinimo,
    this.lote,
    this.dataValidade,
    this.createdAt,
    this.taxRule,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'].toString(),
      nome: json['nome'] as String,
      substanciaActiva: json['substanciaActiva'] as String?,
      dosagem: json['dosagem'] as String?,
      forma: json['forma'] as String?,
      apresentacao: json['apresentacao'] as String?,
      ativo: _toBool(json['ativo'] ?? json['activo'], defaultValue: true),
      barcode: json['barcode'] as String?,
      categoria: _parseCategoria(json),
      tipoDispensacao: json['tipoDispensacao'] as String? ?? 'VENDA_LIVRE',
      requiresPrescription: _toBool(json['requiresPrescription']),
      requiresDoubleCheck: _toBool(json['requiresDoubleCheck']),
      requiresPsychotropicBook: _toBool(json['requiresPsychotropicBook']),
      precoVenda: _toDouble(json['precoVenda']),
      estoqueAtual: _toDouble(json['estoqueAtual']),
      estoqueMinimo: _toDouble(json['estoqueMinimo']),
      lote: _readLote(json),
      dataValidade: _readDataValidade(json),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      taxRule: _parseTaxRule(json['taxRule'], parent: json),
    );
  }

  static CategoriaProduto _parseCategoria(Map<String, dynamic> json) {
    final categoria = json['categoria'];
    if (categoria is String) {
      return CategoriaProdutoX.fromApi(categoria);
    }
    if (categoria is Map<String, dynamic>) {
      final nome = categoria['nome'] as String?;
      if (nome != null && nome.trim().isNotEmpty) {
        return _categoriaFromNome(nome);
      }
    }
    final categoriaNome = json['categoriaNome'] as String?;
    if (categoriaNome != null && categoriaNome.trim().isNotEmpty) {
      return _categoriaFromNome(categoriaNome);
    }
    return CategoriaProduto.medicamento;
  }

  static ProductTaxRule? _parseTaxRule(
    dynamic value, {
    Map<String, dynamic>? parent,
  }) {
    final taxRuleId = parent?['taxRuleId']?.toString();
    if (value is! Map<String, dynamic>) {
      if (taxRuleId == null || taxRuleId.isEmpty) {
        return null;
      }
      return ProductTaxRule(
        id: taxRuleId,
        tipo: parent?['taxRuleTipo'] as String? ?? 'IVA_NORMAL',
        taxa: _toDouble(parent?['taxaIva'] ?? parent?['taxRuleTaxa']),
        codigo: parent?['taxRuleCodigo'] as String?,
        nome: parent?['taxRuleNome'] as String?,
        descricao: parent?['taxRuleDescricao'] as String?,
        ativo: _toBool(parent?['taxRuleAtivo'], defaultValue: true),
      );
    }
    return ProductTaxRule(
      id: value['id']?.toString() ?? taxRuleId,
      tipo: value['tipo'] as String? ?? 'IVA_NORMAL',
      taxa: _toDouble(value['taxa']),
      codigo: value['codigo'] as String?,
      nome: value['nome'] as String?,
      descricao: value['descricao'] as String?,
      ativo: _toBool(value['ativo'], defaultValue: true),
    );
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

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) {
      return defaultValue;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
    return defaultValue;
  }

  static String? _readLote(Map<String, dynamic> json) {
    final direct = json['lote'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    return _firstLote(json['lotes']);
  }

  static DateTime? _readDataValidade(Map<String, dynamic> json) {
    final direct = json['dataValidade'];
    if (direct is String && direct.trim().isNotEmpty) {
      return DateTime.tryParse(direct);
    }
    return _firstDataValidade(json['lotes']);
  }

  static String? _firstLote(dynamic value) {
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) {
        return first['numeroLote'] as String?;
      }
    }
    return null;
  }

  static DateTime? _firstDataValidade(dynamic value) {
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) {
        final dataValidadeStr = first['dataValidade'] as String?;
        if (dataValidadeStr != null) {
          return DateTime.tryParse(dataValidadeStr);
        }
      }
    }
    return null;
  }

  static CategoriaProduto _categoriaFromNome(String nome) {
    final normalized = nome.trim().toLowerCase();
    switch (normalized) {
      case 'consumiveis':
      case 'consumíveis':
      case 'consumivel':
      case 'consumível':
        return CategoriaProduto.consumivel;
      case 'equipamentos':
      case 'equipamento':
        return CategoriaProduto.equipamento;
      case 'higiene':
        return CategoriaProduto.higiene;
      case 'suplementos':
      case 'suplemento':
        return CategoriaProduto.suplemento;
      case 'outros':
      case 'outro':
        return CategoriaProduto.outro;
      case 'medicamentos':
      case 'medicamento':
      default:
        return CategoriaProduto.medicamento;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'substanciaActiva': substanciaActiva,
      'dosagem': dosagem,
      'forma': forma,
      'apresentacao': apresentacao,
      'ativo': ativo,
      'activo': ativo,
      'barcode': barcode,
      'categoria': categoria.apiValue,
      'tipoDispensacao': tipoDispensacao,
      'requiresPrescription': requiresPrescription,
      'requiresDoubleCheck': requiresDoubleCheck,
      'requiresPsychotropicBook': requiresPsychotropicBook,
      'precoVenda': precoVenda,
      'estoqueAtual': estoqueAtual,
      'estoqueMinimo': estoqueMinimo,
      'taxRuleId': taxRule?.id,
      'lote': lote,
      'dataValidade': dataValidade?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
