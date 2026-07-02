import 'package:flutter/material.dart';

import '../../../../../../core/theme/design_tokens.dart';
import '../../../../../../core/theme/spacing.dart';

/// Card de lote na aba Lotes.
class LotCard extends StatelessWidget {
  const LotCard({super.key, required this.lote});

  final Map<String, dynamic> lote;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    final numero = lote['numeroLote']?.toString() ?? '—';
    final quantidade = lote['quantidadeAtual']?.toString() ?? '0';
    final validade = _formatDate(lote['dataValidade']);
    final estado = lote['estadoSanitario']?.toString() ?? 'NORMAL';
    final estadoColor = _estadoColor(t, estado);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: Padding(
        padding: EdgeInsets.all(s.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    numero,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _estadoLabel(estado),
                    style: TextStyle(
                      color: estadoColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: s.sm),
            Row(
              children: [
                _Metric(label: 'Quantidade', value: quantidade, t: t),
                SizedBox(width: s.lg),
                _Metric(label: 'Validade', value: validade, t: t),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(dynamic value) {
    if (value == null) return '—';
    final text = value.toString();
    if (text.length >= 10) return text.substring(0, 10);
    return text;
  }

  static Color _estadoColor(PharmaTokens t, String estado) {
    switch (estado.toUpperCase()) {
      case 'QUARENTENA':
        return t.posWarning;
      case 'RECALL':
      case 'EXPIRADO':
        return t.posDanger;
      default:
        return t.brandGreen;
    }
  }

  static String _estadoLabel(String estado) {
    switch (estado.toUpperCase()) {
      case 'QUARENTENA':
        return 'Quarentena';
      case 'RECALL':
        return 'Recall';
      case 'EXPIRADO':
        return 'Expirado';
      default:
        return 'Normal';
    }
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.t});

  final String label;
  final String value;
  final PharmaTokens t;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: t.textMuted, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
