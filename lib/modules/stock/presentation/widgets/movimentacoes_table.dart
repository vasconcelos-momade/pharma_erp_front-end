import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../domain/entities/movimentacao.dart';

class MovimentacoesTable extends StatelessWidget {
  const MovimentacoesTable({super.key, required this.items});

  final List<Movimentacao> items;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final textTheme = Theme.of(context).textTheme;

    return EnterpriseDataTable(
      columns: [
        DataColumn(label: Text('Data', style: _headerStyle(textTheme, t))),
        DataColumn(label: Text('Tipo', style: _headerStyle(textTheme, t))),
        DataColumn(label: Text('Produto', style: _headerStyle(textTheme, t))),
        DataColumn(label: Text('Lote', style: _headerStyle(textTheme, t))),
        DataColumn(label: Text('Qtd', style: _headerStyle(textTheme, t))),
        DataColumn(label: Text('Stock', style: _headerStyle(textTheme, t))),
        DataColumn(label: Text('Origem', style: _headerStyle(textTheme, t))),
        DataColumn(label: Text('Documento', style: _headerStyle(textTheme, t))),
        DataColumn(
          label: Text('Utilizador', style: _headerStyle(textTheme, t)),
        ),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final item = items[index];
        final tipoColor = _tipoColor(t, item.tipo);
        final produtoNome = item.produto?.nome ?? '—';
        final barcode = item.produto?.barcode;
        final produtoLabel = barcode == null || barcode.isEmpty
            ? produtoNome
            : '$produtoNome · $barcode';

        return DataRow(
          cells: [
            DataCell(
              Text(
                _formatDateTime(item.createdAt),
                style: _cellStyle(textTheme, t),
              ),
            ),
            DataCell(
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.sm,
                  vertical: context.spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: tipoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tipoColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  item.tipoLabel,
                  style: textTheme.erpOverline.copyWith(color: tipoColor),
                ),
              ),
            ),
            DataCell(Text(produtoLabel, style: _cellStyle(textTheme, t))),
            DataCell(
              Text(
                item.lote?.numeroLote ?? '—',
                style: _cellStyle(textTheme, t),
              ),
            ),
            DataCell(
              Text(
                _formatQty(item.quantidade),
                style: textTheme.erpLabel.copyWith(color: t.textPrimary),
              ),
            ),
            DataCell(
              Text(
                '${_formatQty(item.estoqueAnterior)} → ${_formatQty(item.estoqueFinal)}',
                style: _cellStyle(textTheme, t, muted: true),
              ),
            ),
            DataCell(Text(item.origemLabel, style: _cellStyle(textTheme, t))),
            DataCell(
              Text(
                item.documentoReferencia ?? '—',
                style: _cellStyle(textTheme, t, muted: true),
              ),
            ),
            DataCell(
              Text(item.user?.nome ?? '—', style: _cellStyle(textTheme, t)),
            ),
          ],
        );
      },
    );
  }

  TextStyle _headerStyle(TextTheme textTheme, PharmaTokens t) {
    return textTheme.erpOverline.copyWith(color: t.textMuted);
  }

  TextStyle _cellStyle(
    TextTheme textTheme,
    PharmaTokens t, {
    bool muted = false,
  }) {
    return muted
        ? textTheme.erpBodySecondary.copyWith(color: t.textMuted)
        : textTheme.erpLabel.copyWith(color: t.textPrimary);
  }

  Color _tipoColor(PharmaTokens t, MovimentacaoTipo? tipo) {
    return switch (tipo) {
      MovimentacaoTipo.entrada => t.brandGreen,
      MovimentacaoTipo.saida => t.posDanger,
      MovimentacaoTipo.ajuste => t.brandBlue,
      MovimentacaoTipo.devolucao => t.posWarning,
      MovimentacaoTipo.quarentena => t.posWarning,
      MovimentacaoTipo.incineracao => t.textMuted,
      null => t.textMuted,
    };
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
