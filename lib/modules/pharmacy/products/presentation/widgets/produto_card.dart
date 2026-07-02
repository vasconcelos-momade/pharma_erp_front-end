import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/spacing.dart';
import '../../domain/entities/product.dart';
import 'detail/status_badge.dart';

class ProdutoCard extends StatelessWidget {
  const ProdutoCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAction,
  });

  final Product product;
  final VoidCallback onTap;
  final void Function(String action) onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);
    final lowStock = product.estoqueAtual <= product.estoqueMinimo;
    final substancia = product.substanciaActiva?.trim();

    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(t.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: t.iconSm,
                    color: t.textPrimary,
                  ),
                  SizedBox(width: s.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.nome,
                          style: theme.textTheme.erpLabel.copyWith(
                            color: t.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (substancia != null && substancia.isNotEmpty) ...[
                          SizedBox(height: s.xxs),
                          Text(
                            'Substância activa: $substancia',
                            style: theme.textTheme.erpCaption.copyWith(
                              color: t.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: s.xs),
                  StatusBadge(active: product.ativo),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: t.minTouchTarget * 0.6,
                      minHeight: t.minTouchTarget * 0.6,
                    ),
                    icon: Icon(Icons.more_vert, size: t.iconSm, color: t.textMuted),
                    onSelected: onAction,
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'detalhes',
                        child: Text('Ver detalhes'),
                      ),
                      PopupMenuItem(
                        value: 'editar',
                        child: Text('Editar'),
                      ),
                      PopupMenuItem(
                        value: 'excluir',
                        child: Text('Excluir'),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: s.xs),
              Text(
                product.dosagem ?? '—',
                style: theme.textTheme.erpCaption.copyWith(color: t.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: s.xxs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.forma ?? '—',
                      style: theme.textTheme.erpCaption.copyWith(color: t.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Stock: ${_formatNumber(product.estoqueAtual)}',
                    style: theme.textTheme.erpLabel.copyWith(
                      color: lowStock ? t.posDanger : t.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
