import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';

/// Lista de produtos (demo UI — ligação a dados em `data/` mais tarde).
class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final rows = [
      ('Amoxicilina 500mg', 'AN-2023-45', 120, 'OK'),
      ('Diazepam 10mg', 'AN-2023-90', 45, 'PSI'),
      ('Álcool 70%', 'AN-GEN-02', 200, 'OK'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRODUTOS & STOCK',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: EnterpriseDataTable(
            columns: [
              DataColumn(label: Text('PRODUTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.textMuted))),
              DataColumn(label: Text('ANARME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.textMuted))),
              DataColumn(label: Text('STOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.textMuted))),
              DataColumn(label: Text('ESTADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.textMuted))),
            ],
            rowCount: rows.length,
            rowBuilder: (c, i) {
              final r = rows[i];
              return DataRow(
                cells: [
                  DataCell(Text(r.$1, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700))),
                  DataCell(Text(r.$2, style: TextStyle(color: t.textMuted))),
                  DataCell(Text('${r.$3} u.', style: TextStyle(color: t.textSecondary, fontWeight: FontWeight.w700))),
                  DataCell(
                    Chip(
                      label: Text(r.$4),
                      backgroundColor: r.$4 == 'PSI' ? t.psychotropic.withValues(alpha: 0.2) : t.brandGreen.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
