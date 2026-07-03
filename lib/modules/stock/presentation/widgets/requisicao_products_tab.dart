import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/layout/enterprise_module_search_bar.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../pharmacy/products/domain/entities/categoria_produto.dart';
import '../../../pharmacy/products/domain/entities/product.dart';
import '../../../pharmacy/products/presentation/providers/product_provider.dart';

/// Lista de produtos partilhada por Compra, Entrada e Saída.
class RequisicaoProductsTab extends StatelessWidget {
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
  final ValueChanged<CategoriaProduto?> onCategoriaChanged;
  final Future<void> Function() onRefreshProducts;
  final Future<void> Function(int page) onGoToPage;
  final ValueChanged<Product> onSelectProduct;
  final bool showPagination;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final products = productState.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: EnterpriseModuleSearchBar(
                controller: searchController,
                hintText:
                    'Pesquisar por nome, princípio ativo, lote ou código de barras...',
                enabled: !productState.isLoading,
                onSubmitted: onSearchChanged,
                onChanged: onSearchChanged,
              ),
            ),
            SizedBox(width: s.sm),
            IconButton(
              onPressed: productState.isLoading ? null : onRefreshProducts,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualizar catálogo',
            ),
          ],
        ),
        SizedBox(height: s.sm),
        SizedBox(
          width: 260,
          child: DropdownButtonFormField<CategoriaProduto?>(
            initialValue: productState.categoria,
            decoration: InputDecoration(
              labelText: 'Categoria',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(t.radiusMd),
                borderSide: BorderSide(color: t.border),
              ),
              filled: true,
              fillColor: t.bgPrimary.withValues(alpha: 0.5),
            ),
            items: [
              const DropdownMenuItem<CategoriaProduto?>(
                value: null,
                child: Text('Todas'),
              ),
              ...CategoriaProduto.values.map(
                (categoria) => DropdownMenuItem<CategoriaProduto?>(
                  value: categoria,
                  child: Text(categoria.label),
                ),
              ),
            ],
            onChanged: onCategoriaChanged,
          ),
        ),
        if (productState.isLoading)
          Padding(
            padding: EdgeInsets.only(top: s.sm),
            child: const LinearProgressIndicator(),
          ),
        if (productState.errorMessage != null) ...[
          SizedBox(height: s.sm),
          _RequisicaoProductsInlineBanner(
            message: productState.errorMessage!,
            icon: Icons.error_outline_rounded,
            color: t.posDanger,
          ),
        ],
        SizedBox(height: s.md),
        Expanded(
          child: !productState.isInitialized && productState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : products.isEmpty
              ? const ModuleEmptyState(
                  title: 'Nenhum produto ativo encontrado',
                  subtitle:
                      'Ajuste a pesquisa ou actualize o catálogo para tentar novamente.',
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 768) {
                      return ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const EnterpriseListDivider(),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return _RequisicaoProductCard(
                            product: product,
                            enabled: canAddItems,
                            onTap: () => onSelectProduct(product),
                          );
                        },
                      );
                    }

                    return EnterpriseDataTable(
                      adaptive: false,
                      showCheckboxColumn: false,
                      columns: [
                        for (final label in [
                          'PRODUTO',
                          'CATEGORIA',
                          'SUBSTÂNCIA',
                          'DOSAGEM',
                          'LOTE',
                          'VALIDADE',
                          'ESTADO',
                          'AÇÕES',
                        ])
                          DataColumn(
                            label: Text(
                              label,
                              style: Theme.of(context).textTheme.erpOverline.copyWith(
                                    color: t.textMuted,
                                  ),
                            ),
                          ),
                      ],
                      rowCount: products.length,
                      rowBuilder: (context, index) {
                        final product = products[index];
                        final validade = product.dataValidade != null
                            ? '${product.dataValidade!.day.toString().padLeft(2, '0')}/'
                                  '${product.dataValidade!.month.toString().padLeft(2, '0')}/'
                                  '${product.dataValidade!.year}'
                            : '—';
                        return DataRow(
                          onSelectChanged: canAddItems ? (_) => onSelectProduct(product) : null,
                          cells: [
                            DataCell(Text(product.nome)),
                            DataCell(Text(product.categoria.label)),
                            DataCell(Text(product.substanciaActiva ?? '—')),
                            DataCell(Text(product.dosagem ?? '—')),
                            DataCell(Text(product.lote?.trim().isNotEmpty == true ? product.lote! : '—')),
                            DataCell(Text(validade)),
                            DataCell(
                              Text(
                                product.ativo ? 'Activo' : 'Inactivo',
                                style: Theme.of(context).textTheme.erpLabel.copyWith(
                                  color: product.ativo ? t.brandGreen : t.textMuted,
                                ),
                              ),
                            ),
                            DataCell(
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FilledButton.tonalIcon(
                                  onPressed: canAddItems ? () => onSelectProduct(product) : null,
                                  icon: const Icon(Icons.add_shopping_cart_rounded),
                                  label: const Text('Adicionar'),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
        ),
        if (showPagination && productState.isInitialized) ...[
          EnterprisePagination(
            page: productState.page,
            pageSize: productState.pageSize,
            hasMore: productState.hasMore,
            itemsOnPage: productState.items.length,
            itemLabel: 'produtos',
            isBusy: productState.isLoading,
            onPageChanged: (page) => onGoToPage(page),
            onPageSizeChanged: (_) {},
          ),
        ],
      ],
    );
  }
}

class _RequisicaoProductCard extends StatelessWidget {
  const _RequisicaoProductCard({
    required this.product,
    required this.enabled,
    required this.onTap,
  });

  final Product product;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final statusLabel = product.ativo ? 'Activo' : 'Inactivo';
    final loteLabel = product.lote?.trim();
    final validadeLabel = product.dataValidade != null
        ? '${product.dataValidade!.day.toString().padLeft(2, '0')}/'
              '${product.dataValidade!.month.toString().padLeft(2, '0')}/'
              '${product.dataValidade!.year}'
        : null;
    final productDetails = [
      product.substanciaActiva,
      product.dosagem,
      [
        product.forma,
        product.apresentacao,
      ].whereType<String>().where((value) => value.isNotEmpty).join(' / '),
      if (loteLabel != null && loteLabel.isNotEmpty)
        validadeLabel != null ? 'Lote $loteLabel • val. $validadeLabel' : 'Lote $loteLabel',
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');

    return EnterpriseListCard(
      leading: Icons.inventory_2_outlined,
      title: product.nome,
      subtitle: productDetails.isNotEmpty ? productDetails : product.categoria.label,
      chip: EnterpriseStatusChip(
        label: statusLabel,
        color: product.ativo ? t.brandGreen : t.textMuted,
      ),
      metadata: [
        EnterpriseListCardMeta(label: 'Categoria: ${product.categoria.label}'),
      ],
      actions: IconButton(
        onPressed: enabled ? onTap : null,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        style: IconButton.styleFrom(
          backgroundColor: t.brandBlue.withValues(alpha: 0.1),
          foregroundColor: t.brandBlue,
        ),
        tooltip: 'Adicionar à requisição',
      ),
      onTap: enabled ? onTap : null,
    );
  }
}

class _RequisicaoProductsInlineBanner extends StatelessWidget {
  const _RequisicaoProductsInlineBanner({
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;
  final IconData icon;
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
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: s.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.erpBody.copyWith(color: t.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
