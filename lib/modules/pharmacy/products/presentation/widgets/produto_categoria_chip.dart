import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../domain/entities/categoria_produto.dart';

class ProdutoCategoriaChip extends StatelessWidget {
  const ProdutoCategoriaChip({
    super.key,
    required this.categoria,
    this.label,
    this.compact = true,
  });

  final CategoriaProduto categoria;
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final color = _colorFor(categoria, t);

    return Chip(
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      label: Text(label ?? categoria.label),
      labelStyle: Theme.of(context).textTheme.erpCaption.copyWith(color: color),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
    );
  }

  Color _colorFor(CategoriaProduto categoria, PharmaTokens t) {
    switch (categoria) {
      case CategoriaProduto.medicamento:
        return t.brandBlue;
      case CategoriaProduto.consumivel:
        return t.brandGreen;
      case CategoriaProduto.equipamento:
        return t.textSecondary;
      case CategoriaProduto.higiene:
        return t.posInfo;
      case CategoriaProduto.suplemento:
        return t.posWarning;
      case CategoriaProduto.outro:
        return t.textMuted;
    }
  }
}
