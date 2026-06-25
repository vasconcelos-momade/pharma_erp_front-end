import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../domain/entities/categoria_produto.dart';
import '../../domain/entities/product.dart';
import '../providers/product_provider.dart';
import '../widgets/produto_categoria_chip.dart';
import '../widgets/produto_form_dialog.dart';

/// Catálogo de produtos paginado e pesquisável com regras no backend.
class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(masterProductListProvider).query,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final state = ref.watch(masterProductListProvider);
    final controller = ref.read(masterProductListProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Spacer(),
            FilledButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => _openCreateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Novo produto'),
            ),
          ],
        ),
        SizedBox(height: s.md),
        Wrap(
          spacing: s.sm,
          runSpacing: s.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: _searchController,
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Pesquisar por nome, substância, lote ou código...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: s.md,
                    vertical: s.sm,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<CategoriaProduto?>(
                initialValue: state.categoria,
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  border: const OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: s.md,
                    vertical: s.sm,
                  ),
                ),
                items: [
                  const DropdownMenuItem<CategoriaProduto?>(
                    value: null,
                    child: Text('Todas'),
                  ),
                  ...CategoriaProduto.values.map(
                    (categoria) => DropdownMenuItem(
                      value: categoria,
                      child: Text(categoria.label),
                    ),
                  ),
                ],
                onChanged: controller.setCategoriaFilter,
              ),
            ),
          ],
        ),
        if (state.isLoading) ...[
          SizedBox(height: s.sm),
          const LinearProgressIndicator(),
        ],
        SizedBox(height: s.md),
        if (state.errorMessage != null)
          Padding(
            padding: EdgeInsets.only(bottom: s.sm),
            child: Text(
              state.errorMessage!,
              style: TextStyle(color: t.posDanger),
            ),
          ),
        Expanded(
          child: !state.isInitialized && state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: state.items.isEmpty
                                ? const _InventoryProductsEmptyState()
                                : EnterpriseDataTable(
                                    showCheckboxColumn: false,
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          'PRODUTO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: t.textMuted,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'CATEGORIA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: t.textMuted,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'ESTADO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: t.textMuted,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'AÇÕES',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: t.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                    rowCount: state.items.length,
                                    rowBuilder: (context, index) {
                                      final product = state.items[index];
                                      final isDeleting =
                                          state.deletingProductIds.contains(
                                            product.id,
                                          );
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  product.nome,
                                                  style: TextStyle(
                                                    color: product.ativo
                                                        ? t.textPrimary
                                                        : t.textMuted,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                if ((product.substanciaActiva ?? '')
                                                    .isNotEmpty)
                                                  Text(
                                                    product.substanciaActiva!,
                                                    style: TextStyle(
                                                      color: t.textMuted,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            ProdutoCategoriaChip(
                                              categoria: product.categoria,
                                            ),
                                          ),
                                          DataCell(
                                            _ProductStatusChip(
                                              isActive: product.ativo,
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  tooltip: 'Editar',
                                                  onPressed: isDeleting
                                                      ? null
                                                      : () => _openEditDialog(
                                                          context,
                                                          ref,
                                                          product,
                                                        ),
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: 'Excluir',
                                                  onPressed: isDeleting
                                                      ? null
                                                      : () => _confirmDeleteProduct(
                                                          context,
                                                          ref,
                                                          product,
                                                        ),
                                                  icon: isDeleting
                                                      ? SizedBox(
                                                          width: 18,
                                                          height: 18,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: t.posDanger,
                                                          ),
                                                        )
                                                      : const Icon(
                                                          Icons.delete_outline_rounded,
                                                        ),
                                                  color: t.posDanger,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                          if (state.isInitialized) ...[
                            SizedBox(height: s.sm),
                            _InventoryProductsPaginationBar(
                              page: state.page,
                              pageSize: state.pageSize,
                              itemCount: state.items.length,
                              hasMore: state.hasMore,
                              onPrevious:
                                  state.page > 1 && !state.isLoading
                                  ? () => controller.goToPage(state.page - 1)
                                  : null,
                              onNext: state.hasMore && !state.isLoading
                                  ? () => controller.goToPage(state.page + 1)
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showProdutoFormDialog(context);
    if (result == null || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(masterProductListProvider.notifier)
          .createProduct(result.toPayload());
      if (context.mounted) {
        PharmaFeedback.success(context, 'Produto criado com sucesso');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) {
        PharmaFeedback.error(context, e.message);
      }
    } catch (e) {
      if (context.mounted) {
        PharmaFeedback.error(context, e.toString());
      }
    }
  }

  Future<void> _openEditDialog(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final result = await showProdutoFormDialog(context, product: product);
    if (result == null || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(masterProductListProvider.notifier)
          .updateProduct(product.id, result.toPayload());
      if (context.mounted) {
        PharmaFeedback.success(context, 'Produto actualizado com sucesso');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) {
        PharmaFeedback.error(context, e.message);
      }
    } catch (e) {
      if (context.mounted) {
        PharmaFeedback.error(context, e.toString());
      }
    }
  }

  Future<void> _confirmDeleteProduct(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Confirmar exclusão',
      message:
          'Deseja excluir o produto "${product.nome}"?\n\n'
          'A operação seguirá o padrão actual do sistema e removerá o item da gestão activa.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
    );
    if (!context.mounted || confirmed != true) {
      return;
    }

    try {
      await ref.read(masterProductListProvider.notifier).deleteProduct(product.id);
      if (context.mounted) {
        PharmaFeedback.success(context, 'Produto excluído com sucesso');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) {
        PharmaFeedback.error(context, e.message);
      }
    } catch (e) {
      if (context.mounted) {
        PharmaFeedback.error(context, e.toString());
      }
    }
  }
}

class _InventoryProductsEmptyState extends StatelessWidget {
  const _InventoryProductsEmptyState();

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Card(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(s.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: t.textMuted),
              SizedBox(height: s.md),
              Text(
                'Nenhum produto encontrado',
                style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: s.xs),
              Text(
                'Ajuste a pesquisa, altere a categoria ou avance para outra página.',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryProductsPaginationBar extends StatelessWidget {
  const _InventoryProductsPaginationBar({
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

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Anterior'),
          ),
          const Spacer(),
          Text(
            '$resultsLabel • Página $page',
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
    );
  }
}

class _ProductStatusChip extends StatelessWidget {
  const _ProductStatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final color = isActive ? t.brandGreen : t.posDanger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
