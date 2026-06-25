import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../domain/entities/categoria_produto.dart';

class ProdutoCategoriaChip extends StatelessWidget {
  const ProdutoCategoriaChip({
    super.key,
    required this.categoria,
    this.compact = true,
  });

  final CategoriaProduto categoria;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final color = _colorFor(categoria, t);

    return Chip(
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      label: Text(categoria.label),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: compact ? 11 : 12,
      ),
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
        return const Color(0xFF0EA5E9);
      case CategoriaProduto.suplemento:
        return const Color(0xFFF59E0B);
      case CategoriaProduto.outro:
        return t.textMuted;
    }
  }
}
