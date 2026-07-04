import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
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
    final t = context.pharmaTokens;
    final textTheme = Theme.of(context).textTheme;

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
          DataColumn(
            label: Text(
              label,
              style: textTheme.erpOverline.copyWith(color: t.textMuted),
            ),
          ),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final product = items[index];
        final stockIndisponivel = product.estoqueAtual <= 0;
        final lineId = 'produto:${product.id}';
        final isAdding = addingProductId == lineId;
        final canInteract = canAdd && !isAdding;

        return DataRow(
          onSelectChanged: canInteract ? (_) => onAdd(product) : null,
          cells: [
            DataCell(_nameCell(context, product)),
            DataCell(Text(product.categoriaNome ?? '—')),
            DataCell(Text(pdvFormatMoney(product.precoVenda))),
            DataCell(Text(pdvFormatDate(product.dataValidade))),
            DataCell(Text(product.lote?.trim().isNotEmpty == true ? product.lote! : '—')),
            DataCell(
              Text(
                '${product.estoqueAtual.toInt()}',
                style: textTheme.erpLabel.copyWith(
                  color: stockIndisponivel ? t.posDanger : t.textPrimary,
                ),
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
    final theme = Theme.of(context);
    final substancia = product.nomeGenerico?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          product.nomeComercial,
          style: theme.textTheme.erpLabel.copyWith(color: t.textPrimary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (substancia != null && substancia.isNotEmpty) ...[
          SizedBox(height: s.xxs),
          Text(
            'Nome genérico: $substancia',
            style: theme.textTheme.erpCaption.copyWith(color: t.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
