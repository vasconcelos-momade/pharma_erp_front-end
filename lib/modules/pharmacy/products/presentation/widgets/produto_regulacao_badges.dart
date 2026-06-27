import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../domain/entities/product.dart';

class ProdutoRegulacaoBadges extends StatelessWidget {
  const ProdutoRegulacaoBadges({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];

    if (_isMedicamento(product)) {
      badges.add(_Badge(label: 'Medicamento', color: context.pharmaTokens.brandBlue));
    }
    if (product.antimicrobiano) {
      badges.add(_Badge(label: 'Antimicrobiano', color: Colors.deepPurple));
    }
    if (product.requiresPsychotropicBook ||
        product.tipoDispensacao == 'PSICOTROPICO' ||
        product.tipoDispensacao == 'NARCOTICO') {
      badges.add(_Badge(label: 'Psicotrópico', color: Colors.indigo));
    }
    if (product.requiresPrescription ||
        product.tipoDispensacao == 'RECEITA_OBRIGATORIA' ||
        product.tipoDispensacao == 'RECEITA_CONTROLADA') {
      badges.add(_Badge(label: 'Receita Obrigatória', color: Colors.orange));
    }

    if (badges.isEmpty) {
      return Text(
        _dispensacaoLabel(product.tipoDispensacao),
        style: TextStyle(
          color: context.pharmaTokens.textMuted,
          fontSize: 12,
        ),
      );
    }

    return Wrap(spacing: 4, runSpacing: 4, children: badges);
  }

  bool _isMedicamento(Product product) {
    final nome = product.categoriaNome?.toLowerCase() ?? '';
    return product.categoria.name == 'medicamento' ||
        nome.contains('medicament');
  }

  String _dispensacaoLabel(String tipo) {
    switch (tipo) {
      case 'VENDA_LIVRE':
        return 'Venda livre';
      case 'RECEITA_SIMPLES':
        return 'Receita simples';
      case 'RECEITA_CONTROLADA':
        return 'Receita controlada';
      case 'RECEITA_OBRIGATORIA':
        return 'Receita obrigatória';
      case 'PSICOTROPICO':
        return 'Psicotrópico';
      case 'NARCOTICO':
        return 'Narcótico';
      default:
        return tipo;
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
