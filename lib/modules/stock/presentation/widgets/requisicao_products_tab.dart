import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/layout/enterprise_module_search_bar.dart'
    show EnterpriseModuleSearchBar, enterpriseDropdownDecoration;
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/table_typography.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../pharmacy/categories/presentation/providers/category_provider.dart';
import '../../../pharmacy/products/domain/entities/product.dart';
import '../../../pharmacy/products/presentation/providers/product_provider.dart';

/// Tab de catálogo de produtos para fluxos de requisição (compra, entrada, saída).
class RequisicaoProductsTab extends ConsumerWidget {
  const RequisicaoProductsTab({
    super.key,
    required this.productState,
    required this.searchController,
    required this.canAddItems,
    required this.onSearchChanged,
    required this.onCategoriaChanged,
    required this.onRefreshProducts,
    required this.onGoToPage,
    required this.onSelectProduct,
    this.showPagination = true,
  });

  final ProductListState productState;
  final TextEditingController searchController;
  final bool canAddItems;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoriaChanged;
  final Future<void> Function() onRefreshProducts;
  final Future<void> Function(int page) onGoToPage;
  final ValueChanged<Product> onSelectProduct;
  final bool showPagination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final categories = ref.watch(activeCategoriesProvider).asData?.value ?? const [];

    if (searchController.text != productState.query) {
      searchController.value = TextEditingValue(
        text: productState.query,
        selection: TextSelection.collapsed(offset: productState.query.length),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: EnterpriseModuleSearchBar(
                controller: searchController,
                hintText: 'Pesquisar por nome ou substância activa...',
                enabled: !productState.isLoading,
                onSubmitted: onSearchChanged,
                onChanged: onSearchChanged,
              ),
            ),
            if (categories.isNotEmpty) ...[
              SizedBox(width: s.sm),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: productState.categoriaId,
                  decoration: enterpriseDropdownDecoration(context, 'Categoria'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    for (final category in categories)
                      DropdownMenuItem<String?>(
                        value: category.id,
                        child: Text(category.nome, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: productState.isLoading ? null : onCategoriaChanged,
                ),
              ),
            ],
            SizedBox(width: s.sm),
            IconButton(
              onPressed: productState.isLoading ? null : onRefreshProducts,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualizar lista',
            ),
          ],
        ),
        if (productState.isLoading) ...[
          SizedBox(height: s.sm),
          const LinearProgressIndicator(),
        ],
        if (productState.errorMessage != null) ...[
          SizedBox(height: s.sm),
          _RequisicaoProductsBanner(
            message: productState.errorMessage!,
            color: t.posDanger,
          ),
        ],
        SizedBox(height: s.md),
        Expanded(
          child: !productState.isInitialized && productState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : productState.items.isEmpty
                  ? const _RequisicaoProductsEmptyPane()
                  : EnterpriseDataTable(
                      adaptive: false,
                      showCheckboxColumn: false,
                      columns: [
                        DataColumn(label: TableTypography.headerLabel(context, 'PRODUTO')),
                        DataColumn(label: TableTypography.headerLabel(context, 'CATEGORIA')),
                        DataColumn(label: TableTypography.headerLabel(context, 'ESTOQUE')),
                        DataColumn(label: TableTypography.headerLabel(context, 'AÇÕES')),
                      ],
                      rowCount: productState.items.length,
                      rowBuilder: (context, index) {
                        final product = productState.items[index];
                        return DataRow(
                          onSelectChanged: canAddItems
                              ? (_) => onSelectProduct(product)
                              : null,
                          cells: [
                            DataCell(_productNameCell(context, product)),
                            DataCell(TableTypography.cellText(context, product.categoriaNome ?? '—')),
                            DataCell(TableTypography.cellText(context, _formatStock(product.estoqueAtual))),
                            DataCell(
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FilledButton.tonalIcon(
                                  onPressed: canAddItems
                                      ? () => onSelectProduct(product)
                                      : null,
                                  icon: const Icon(Icons.playlist_add_rounded),
                                  label: const Text('Adicionar'),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
        ),
        if (showPagination &&
            productState.isInitialized &&
            (productState.hasMore || productState.page > 1)) ...[
          EnterprisePagination(
            page: productState.page,
            pageSize: productState.pageSize,
            hasMore: productState.hasMore,
            itemsOnPage: productState.items.length,
            isBusy: productState.isLoading,
            itemLabel: 'produtos',
            onPageChanged: onGoToPage,
            onPageSizeChanged: (_) {},
          ),
        ],
      ],
    );
  }

  Widget _productNameCell(BuildContext context, Product product) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    final substancia = product.nomeGenerico?.trim();
    final formaDosagem = [
      product.forma?.trim(),
      product.dosagem?.trim(),
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');

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
            style: textTheme.erpTableSecondary.copyWith(color: t.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (formaDosagem.isNotEmpty) ...[
          SizedBox(height: s.xxs),
          Text(
            formaDosagem,
            style: textTheme.erpTableMeta.copyWith(color: t.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String _formatStock(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}

class _RequisicaoProductsBanner extends StatelessWidget {
  const _RequisicaoProductsBanner({
    required this.message,
    required this.color,
  });

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.erpBody.copyWith(color: t.textPrimary),
      ),
    );
  }
}

class _RequisicaoProductsEmptyPane extends StatelessWidget {
  const _RequisicaoProductsEmptyPane();

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(s.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: t.textMuted),
            SizedBox(height: s.md),
            Text(
              'Nenhum produto encontrado',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
            ),
            SizedBox(height: s.xs),
            Text(
              'Ajuste a pesquisa ou actualize a lista para tentar novamente.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
