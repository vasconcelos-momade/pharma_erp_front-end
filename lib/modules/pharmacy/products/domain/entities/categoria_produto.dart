enum CategoriaProduto {
  medicamento,
  consumivel,
  equipamento,
  higiene,
  suplemento,
  outro,
}

extension CategoriaProdutoX on CategoriaProduto {
  String get apiValue {
    switch (this) {
      case CategoriaProduto.medicamento:
        return 'MEDICAMENTO';
      case CategoriaProduto.consumivel:
        return 'CONSUMIVEL';
      case CategoriaProduto.equipamento:
        return 'EQUIPAMENTO';
      case CategoriaProduto.higiene:
        return 'HIGIENE';
      case CategoriaProduto.suplemento:
        return 'SUPLEMENTO';
      case CategoriaProduto.outro:
        return 'OUTRO';
    }
  }

  String get label {
    switch (this) {
      case CategoriaProduto.medicamento:
        return 'Medicamento';
      case CategoriaProduto.consumivel:
        return 'Consumível';
      case CategoriaProduto.equipamento:
        return 'Equipamento';
      case CategoriaProduto.higiene:
        return 'Higiene';
      case CategoriaProduto.suplemento:
        return 'Suplemento';
      case CategoriaProduto.outro:
        return 'Outro';
    }
  }

  static CategoriaProduto fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'CONSUMIVEL':
        return CategoriaProduto.consumivel;
      case 'EQUIPAMENTO':
        return CategoriaProduto.equipamento;
      case 'HIGIENE':
        return CategoriaProduto.higiene;
      case 'SUPLEMENTO':
        return CategoriaProduto.suplemento;
      case 'OUTRO':
        return CategoriaProduto.outro;
      case 'MEDICAMENTO':
      default:
        return CategoriaProduto.medicamento;
    }
  }
}
