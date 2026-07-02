import 'package:flutter/material.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';

class ProdutoEmptyState extends StatelessWidget {
  const ProdutoEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(s.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: t.textMuted.withValues(alpha: 0.5)),
            SizedBox(height: s.md),
            Text(
              'Nenhum produto encontrado',
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            SizedBox(height: s.xs),
            Text(
              'Ajuste os filtros ou crie um novo produto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
