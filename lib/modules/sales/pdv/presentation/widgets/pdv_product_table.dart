import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/table_typography.dart';
import '../../../../pharmacy/products/domain/entities/product.dart';
import 'pdv_catalog_utils.dart';

class PdvProductTable extends StatelessWidget {
  const PdvProductTable({
    super.key,
    required this.items,
    required this.query,
    required this.canAdd,
    required this.addingProductId,
    required this.onAdd,
  });

  final List<Product> items;
  final String query;
  final bool canAdd;
  final String? addingProductId;
  final void Function(Product product) onAdd;

  static const _columns = [
    'PRODUTO',
    'CATEGORIA',
    'PREÇO',
    'VALIDADE',
    'LOTE',
    'STOCK',
    'ADD',
  ];

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ModuleEmptyState(
        title: query.isEmpty
            ? 'Nenhum produto disponível.'
            : 'Nenhum produto encontrado.',
        subtitle: query.isEmpty ? null : 'Tente outro nome, código ou EAN.',
      );
    }

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      columns: [
        for (final label in _columns)
          DataColumn(label: TableTypography.headerLabel(context, label)),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final t = context.pharmaTokens;
        final product = items[index];
        final lineId = 'produto:${product.id}';
        final isAdding = addingProductId == lineId;
        final canInteract = canAdd && !isAdding;

        return DataRow(
          onSelectChanged: canInteract ? (_) => onAdd(product) : null,
          cells: [
            DataCell(_nameCell(context, product)),
            DataCell(TableTypography.cellText(context, product.categoriaNome ?? '—')),
            DataCell(TableTypography.cellText(context, pdvFormatMoney(product.precoVenda))),
            DataCell(TableTypography.cellText(context, pdvFormatDate(product.dataValidade))),
            DataCell(
              TableTypography.cellText(
                context,
                product.lote?.trim().isNotEmpty == true ? product.lote! : '—',
              ),
            ),
            DataCell(
              TableTypography.cellText(
                context,
                '${product.estoqueAtual.toInt()}',
                style: TableTypography.primary(context),
              ),
            ),
            DataCell(
              Align(
                alignment: Alignment.center,
                child: FilledButton(
                  onPressed: canInteract ? () => onAdd(product) : null,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(t.minTouchTarget * 0.75, t.minTouchTarget * 0.75),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: isAdding
                      ? PharmaButtonLoader(color: t.bgPrimary)
                      : const Text('+'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _nameCell(BuildContext context, Product product) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    final substancia = product.nomeGenerico?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          product.nomeComercial,
          style: textTheme.erpTablePrimary.copyWith(color: t.textPrimary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (substancia != null && substancia.isNotEmpty) ...[
          SizedBox(height: s.xxs),
          Text(
            substancia,
            style: textTheme.erpTableMeta.copyWith(color: t.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
