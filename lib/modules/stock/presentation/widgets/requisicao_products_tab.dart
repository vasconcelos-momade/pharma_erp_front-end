import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
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
              : ListView.separated(
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
                ),
        ),
        if (showPagination && productState.isInitialized) ...[
          SizedBox(height: s.sm),
          RequisicaoProductsPaginationBar(
            page: productState.page,
            pageSize: productState.pageSize,
            itemCount: productState.items.length,
            hasMore: productState.hasMore,
            onPrevious: productState.page > 1 && !productState.isLoading
                ? () => onGoToPage(productState.page - 1)
                : null,
            onNext: productState.hasMore && !productState.isLoading
                ? () => onGoToPage(productState.page + 1)
                : null,
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
    final s = context.spacing;
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

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: Container(
        padding: EdgeInsets.all(s.md),
        decoration: BoxDecoration(
          color: t.bgPrimary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(t.radiusMd),
          border: Border.all(
            color: enabled ? t.border : t.border.withValues(alpha: 0.5),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 480;
            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nome,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: s.xs),
                  child: ProdutoCategoriaChip(categoria: product.categoria),
                ),
                if (productDetails.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: s.xs),
                    child: Text(
                      productDetails,
                      style: TextStyle(color: t.textMuted, fontSize: 12),
                    ),
                  ),
              ],
            );

            final actions = compact
                ? Wrap(
                    spacing: s.sm,
                    runSpacing: s.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _RequisicaoProductInfoTag(
                        label: statusLabel,
                        color: product.ativo ? t.brandGreen : t.textMuted,
                      ),
                      FilledButton.icon(
                        onPressed: enabled ? onTap : null,
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: const Text('Adicionar'),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RequisicaoProductInfoTag(
                        label: statusLabel,
                        color: product.ativo ? t.brandGreen : t.textMuted,
                      ),
                      SizedBox(width: s.sm),
                      IconButton(
                        onPressed: enabled ? onTap : null,
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: t.brandBlue.withValues(alpha: 0.1),
                          foregroundColor: t.brandBlue,
                        ),
                        tooltip: 'Adicionar à requisição',
                      ),
                    ],
                  );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  info,
                  SizedBox(height: s.md),
                  actions,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: info),
                SizedBox(width: s.md),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RequisicaoProductInfoTag extends StatelessWidget {
  const _RequisicaoProductInfoTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(t.radiusMd),
      ),
      child: Text(
        label,
        style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600),
      ),
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
            child: Text(message, style: TextStyle(color: t.textPrimary)),
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
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: s.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textMuted),
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
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w600,
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
                      style: TextStyle(
                        color: t.textMuted,
                        fontWeight: FontWeight.w600,
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
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
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
