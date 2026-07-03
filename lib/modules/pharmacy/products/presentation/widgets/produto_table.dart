import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../domain/entities/product.dart';
import 'detail/status_badge.dart';
import 'produto_categoria_chip.dart';

/// Colunas alinhadas ao modelo [Product] / schema de produtos.
class ProdutoTable extends StatelessWidget {
  const ProdutoTable({
    super.key,
    required this.items,
    required this.sortBy,
    required this.sortOrder,
    required this.onSort,
    required this.onSelect,
    required this.onAction,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onToggleSelectAll,
  });

  final List<Product> items;
  final String sortBy;
  final String sortOrder;
  final void Function(String column, String order) onSort;
  final void Function(Product) onSelect;
  final void Function(Product, String) onAction;
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onToggleSelect;
  final void Function(bool selected) onToggleSelectAll;

  static const _columnLabels = [
    'Nome',
    'Dosagem',
    'Forma',
    'Categoria',
    'Estoque',
    'Status',
    'Ações',
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final theme = Theme.of(context);

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: true,
      sortColumnIndex: _sortColumnIndex(),
      sortAscending: sortOrder == 'asc',
      onSelectAll: (selected) => onToggleSelectAll(selected ?? false),
      columns: [
        for (var i = 0; i < _columnLabels.length; i++)
          _buildColumn(
            context,
            label: _columnLabels[i],
            onSort: _sortKeyForIndex(i) != null
                ? () => _handleSort(_sortKeyForIndex(i)!)
                : null,
            numeric: i == 4,
          ),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final product = items[index];
        final isSelected = selectedIds.contains(product.id);
        final lowStock = product.estoqueAtual <= product.estoqueMinimo;

        return DataRow(
          selected: isSelected,
          onSelectChanged: (selected) {
            if (selected != null) onToggleSelect(product.id, selected);
          },
          cells: [
            DataCell(
              _nameCell(context, product),
              onTap: () => onSelect(product),
            ),
            DataCell(_cellText(context, product.dosagem)),
            DataCell(_cellText(context, product.forma)),
            DataCell(
              ProdutoCategoriaChip(
                categoria: product.categoria,
                label: product.categoriaNome,
              ),
            ),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatNumber(product.estoqueAtual),
                    style: theme.textTheme.erpLabel.copyWith(
                      color: lowStock ? t.posDanger : t.textPrimary,
                    ),
                  ),
                  if (product.estoqueMinimo > 0)
                    Text(
                      'Mín. ${_formatNumber(product.estoqueMinimo)}',
                      style: theme.textTheme.erpCaption.copyWith(
                        color: t.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            DataCell(StatusBadge(active: product.ativo)),
            DataCell(
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: t.textMuted, size: t.iconSm),
                tooltip: 'Acções',
                onSelected: (action) => onAction(product, action),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'detalhes', child: Text('Ver detalhes')),
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'excluir', child: Text('Eliminar')),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  DataColumn _buildColumn(
    BuildContext context, {
    required String label,
    VoidCallback? onSort,
    bool numeric = false,
  }) {
    final t = context.pharmaTokens;

    return DataColumn(
      numeric: numeric,
      label: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.erpOverline.copyWith(
              color: t.textMuted,
            ),
      ),
      onSort: onSort == null ? null : (_, _) => onSort(),
    );
  }

  Widget _nameCell(BuildContext context, Product product) {
    final t = context.pharmaTokens;
    final theme = Theme.of(context);
    final substancia = product.substanciaActiva?.trim();

    return Column(
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
          SizedBox(height: context.spacing.xxs),
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
    );
  }

  Widget _cellText(BuildContext context, String? value) {
    final t = context.pharmaTokens;
    return Text(
      _orDash(value),
      style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
            color: t.textSecondary,
          ),
    );
  }

  String? _sortKeyForIndex(int index) {
    return switch (index) {
      0 => 'nome',
      4 => 'estoqueAtual',
      _ => null,
    };
  }

  int? _sortColumnIndex() {
    return switch (sortBy) {
      'nome' => 0,
      'estoqueAtual' => 4,
      _ => null,
    };
  }

  void _handleSort(String column) {
    if (sortBy == column) {
      onSort(column, sortOrder == 'asc' ? 'desc' : 'asc');
    } else {
      onSort(column, 'asc');
    }
  }

  String _orDash(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '—';
    return trimmed;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
