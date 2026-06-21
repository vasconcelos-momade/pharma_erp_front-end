import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../domain/entities/movimentacao.dart';

class MovimentacoesTable extends StatelessWidget {
  const MovimentacoesTable({
    super.key,
    required this.items,
  });

  final List<Movimentacao> items;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return EnterpriseDataTable(
      columns: [
        DataColumn(label: Text('Data', style: _headerStyle(t))),
        DataColumn(label: Text('Tipo', style: _headerStyle(t))),
        DataColumn(label: Text('Produto', style: _headerStyle(t))),
        DataColumn(label: Text('Lote', style: _headerStyle(t))),
        DataColumn(label: Text('Qtd', style: _headerStyle(t))),
        DataColumn(label: Text('Stock', style: _headerStyle(t))),
        DataColumn(label: Text('Origem', style: _headerStyle(t))),
        DataColumn(label: Text('Documento', style: _headerStyle(t))),
        DataColumn(label: Text('Utilizador', style: _headerStyle(t))),
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
            DataCell(Text(_formatDateTime(item.createdAt), style: _cellStyle(t))),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tipoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tipoColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  item.tipoLabel,
                  style: TextStyle(
                    color: tipoColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            DataCell(Text(produtoLabel, style: _cellStyle(t))),
            DataCell(Text(item.lote?.numeroLote ?? '—', style: _cellStyle(t))),
            DataCell(
              Text(
                _formatQty(item.quantidade),
                style: _cellStyle(t).copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            DataCell(
              Text(
                '${_formatQty(item.estoqueAnterior)} → ${_formatQty(item.estoqueFinal)}',
                style: _cellStyle(t, muted: true),
              ),
            ),
            DataCell(Text(item.origemLabel, style: _cellStyle(t))),
            DataCell(
              Text(
                item.documentoReferencia ?? '—',
                style: _cellStyle(t, muted: true),
              ),
            ),
            DataCell(Text(item.user?.nome ?? '—', style: _cellStyle(t))),
          ],
        );
      },
    );
  }

  TextStyle _headerStyle(PharmaTokens t) {
    return TextStyle(
      color: t.textMuted,
      fontWeight: FontWeight.w800,
      fontSize: 12,
    );
  }

  TextStyle _cellStyle(PharmaTokens t, {bool muted = false}) {
    return TextStyle(
      color: muted ? t.textMuted : t.textPrimary,
      fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
    );
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
