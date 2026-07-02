import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../categories/domain/entities/category.dart';
import 'produto_filters_content.dart';

class ProdutoFiltersBottomSheet extends StatelessWidget {
  const ProdutoFiltersBottomSheet({
    super.key,
    required this.initialAtivo,
    required this.initialCategoriaId,
    required this.categories,
    required this.onApply,
  });

  final bool? initialAtivo;
  final String? initialCategoriaId;
  final List<Category> categories;
  final void Function(bool? ativo, String? categoriaId) onApply;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.90,
      minChildSize: 0.30,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(t.radiusXl)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(height: s.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(t.radiusMd / 2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtros',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: t.textMuted, size: t.iconSm),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: t.border.withValues(alpha: 0.45)),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(s.md),
                  children: [
                    ProdutoFiltersContent(
                      initialAtivo: initialAtivo,
                      initialCategoriaId: initialCategoriaId,
                      categories: categories,
                      onApply: (ativo, categoriaId) {
                        onApply(ativo, categoriaId);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
