import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../pharmacy/products/domain/entities/categoria_produto.dart';
import '../../../pharmacy/products/domain/entities/product.dart';
import '../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../../pharmacy/products/presentation/widgets/produto_categoria_chip.dart';

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
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText:
                'Pesquisar por nome, princípio ativo, lote ou código de barras...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              onPressed: productState.isLoading ? null : onRefreshProducts,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualizar catálogo',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(t.radiusMd),
              borderSide: BorderSide(color: t.border),
            ),
            filled: true,
            fillColor: t.bgPrimary.withValues(alpha: 0.5),
          ),
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
              ? const _RequisicaoProductsEmptyPane(
                  icon: Icons.inventory_2_outlined,
                  title: 'Nenhum produto ativo encontrado',
                  subtitle:
                      'Ajuste a pesquisa ou actualize o catálogo para tentar novamente.',
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 768) {
                      return ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (_, _) => SizedBox(height: s.sm),
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
                      columns: const [
                        DataColumn(label: Text('PRODUTO')),
                        DataColumn(label: Text('CATEGORIA')),
                        DataColumn(label: Text('SUBSTÂNCIA')),
                        DataColumn(label: Text('DOSAGEM')),
                        DataColumn(label: Text('LOTE')),
                        DataColumn(label: Text('VALIDADE')),
                        DataColumn(label: Text('ESTADO')),
                        DataColumn(label: Text('AÇÕES')),
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

class _RequisicaoProductsEmptyPane extends StatelessWidget {
  const _RequisicaoProductsEmptyPane({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

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
            Icon(icon, size: 48, color: t.textMuted),
            SizedBox(height: s.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.erpCardTitle.copyWith(
                    color: t.textPrimary,
                  ),
            ),
            SizedBox(height: s.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                    color: t.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class RequisicaoProductsPaginationBar extends StatelessWidget {
  const RequisicaoProductsPaginationBar({
    super.key,
    required this.page,
    required this.pageSize,
    required this.itemCount,
    required this.hasMore,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int pageSize;
  final int itemCount;
  final bool hasMore;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final start = itemCount == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final end = itemCount == 0 ? 0 : start + itemCount - 1;
    final resultsLabel = itemCount == 0
        ? 'Sem resultados nesta página'
        : 'Mostrando $start-$end';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(t.radiusMd),
            border: Border.all(color: t.border.withValues(alpha: 0.5)),
          ),
          child: compact
              ? Row(
                  children: [
                    OutlinedButton(
                      onPressed: onPrevious,
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(t.minTouchTarget, t.minTouchTarget),
                        padding: EdgeInsets.symmetric(horizontal: s.sm),
                      ),
                      child: Icon(Icons.chevron_left_rounded, size: t.iconSm),
                    ),
                    SizedBox(width: s.sm),
                    Expanded(
                      child: Text(
                        '$resultsLabel • Página $page',
                        style: Theme.of(context).textTheme.erpLabel.copyWith(
                              color: t.textPrimary,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: s.sm),
                    FilledButton(
                      onPressed: onNext,
                      style: FilledButton.styleFrom(
                        minimumSize: Size(t.minTouchTarget, t.minTouchTarget),
                        padding: EdgeInsets.symmetric(horizontal: s.sm),
                      ),
                      child: Icon(Icons.chevron_right_rounded, size: t.iconSm),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      resultsLabel,
                      style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                            color: t.textMuted,
                          ),
                    ),
                    SizedBox(height: s.sm),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: onPrevious,
                          icon: const Icon(Icons.chevron_left_rounded),
                          label: const Text('Anterior'),
                        ),
                        const Spacer(),
                        Text(
                          'Página $page',
                          style: Theme.of(context).textTheme.erpLabel.copyWith(
                                color: t.textPrimary,
                              ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: onNext,
                          icon: const Icon(Icons.chevron_right_rounded),
                          label: const Text('Seguinte'),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}
