import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../../stock/presentation/providers/fornecedor_provider.dart';
import '../../domain/entities/product.dart';
import '../providers/product_provider.dart';
import '../widgets/produto_categoria_chip.dart';
import '../widgets/produto_detail_panel.dart';
import '../widgets/produto_form_dialog.dart';
import '../widgets/produto_regulacao_badges.dart';
import '../../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../../presentation/widgets/pharmacy_report_exports.dart';

/// Catálogo master de produtos com filtros API, ordenação e painel de detalhe.
class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  late final TextEditingController _searchController;
  String _reportPath = ReportPaths.pharmacyProductsCatalog;

  static const _reportOptions = <(String, String)>[
    (ReportPaths.pharmacyProductsCatalog, 'Catálogo'),
    (ReportPaths.pharmacyProductsByCategory, 'Por categoria'),
    (ReportPaths.pharmacyProductsBySupplier, 'Por fornecedor'),
    (ReportPaths.pharmacyProductsBySubstancia, 'Por substância'),
    (ReportPaths.pharmacyProductsNoStock, 'Sem stock'),
    (ReportPaths.pharmacyProductsBelowMinStock, 'Abaixo do mínimo'),
    (ReportPaths.pharmacyProductsNearExpiry, 'Próximos da validade'),
    (ReportPaths.pharmacyProductsExpired, 'Expirados'),
    (ReportPaths.pharmacyProductsControlled, 'Controlados'),
  ];

  static const _tipoDispensacaoOptions = <MapEntry<String?, String>>[
    MapEntry(null, 'Todas as regulações'),
    MapEntry('VENDA_LIVRE', 'Venda livre'),
    MapEntry('RECEITA_SIMPLES', 'Receita simples'),
    MapEntry('RECEITA_CONTROLADA', 'Receita controlada'),
    MapEntry('RECEITA_OBRIGATORIA', 'Receita obrigatória'),
    MapEntry('PSICOTROPICO', 'Psicotrópico'),
    MapEntry('NARCOTICO', 'Narcótico'),
  ];

  static const _sortOptions = <MapEntry<String, String>>[
    MapEntry('nome', 'Nome'),
    MapEntry('estoqueAtual', 'Stock'),
    MapEntry('createdAt', 'Data de criação'),
  ];

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
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final suppliersAsync = ref.watch(supplierListProvider);
    final reportQuery = <String, dynamic>{
      if (state.query.isNotEmpty) 'q': state.query,
      if (state.categoriaId != null) 'categoriaId': state.categoriaId,
      if (state.fornecedorId != null) 'fornecedorId': state.fornecedorId,
      if (state.tipoDispensacao != null) 'tipoDispensacao': state.tipoDispensacao,
      if (state.includeInactive) 'includeInactive': true,
      'sortBy': state.sortBy,
      'sortOrder': state.sortOrder,
    };

    if (_searchController.text != state.query) {
      _searchController.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    return EnterpriseModuleHub(
      title: 'Produtos',
      subtitle:
          'Catálogo master com stock, lotes, validades e regras de dispensação.',
      tag: 'Farmácia',
      actions: [
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            key: ValueKey('report-$_reportPath'),
            isExpanded: true,
            initialValue: _reportPath,
            decoration: const InputDecoration(
              labelText: 'Relatório',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _reportOptions
                .map(
                  (option) => DropdownMenuItem(
                    value: option.$1,
                    child: Text(option.$2),
                  ),
                )
                .toList(growable: false),
            onChanged: state.isLoading
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _reportPath = value);
                  },
          ),
        ),
        ...pharmacyReportActions(
          ref: ref,
          enabled: !state.isLoading,
          path: _reportPath,
          queryParameters: reportQuery,
        ),
        OutlinedButton.icon(
          onPressed: state.isLoading
              ? null
              : () => controller.refreshCurrentPage(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
        FilledButton.icon(
          onPressed: state.isLoading
              ? null
              : () => _openCreateDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Novo produto'),
        ),
      ],
      filters: Wrap(
        spacing: s.sm,
        runSpacing: s.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchController,
              onChanged: controller.onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Nome, substância ou código de barras...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: categoriesAsync.when(
              data: (categories) => DropdownButtonFormField<String?>(
                key: ValueKey('categoria-${state.categoriaId}'),
                isExpanded: true,
                initialValue: state.categoriaId,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todas'),
                  ),
                  ...categories.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.nome),
                    ),
                  ),
                ],
                onChanged: controller.setCategoriaIdFilter,
              ),
              loading: () => const InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                child: SizedBox(
                  height: 20,
                  child: LinearProgressIndicator(),
                ),
              ),
              error: (_, _) => const InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                child: Text('Erro ao carregar'),
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: suppliersAsync.when(
              data: (suppliers) => DropdownButtonFormField<String?>(
                key: ValueKey('fornecedor-${state.fornecedorId}'),
                isExpanded: true,
                initialValue: state.fornecedorId,
                decoration: const InputDecoration(
                  labelText: 'Fornecedor',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...suppliers.map(
                    (f) => DropdownMenuItem(
                      value: f.id,
                      child: Text(f.nome),
                    ),
                  ),
                ],
                onChanged: controller.setFornecedorIdFilter,
              ),
              loading: () => const InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fornecedor',
                  border: OutlineInputBorder(),
                ),
                child: SizedBox(
                  height: 20,
                  child: LinearProgressIndicator(),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String?>(
              key: ValueKey('tipo-${state.tipoDispensacao}'),
              isExpanded: true,
              initialValue: state.tipoDispensacao,
              decoration: const InputDecoration(
                labelText: 'Regulação',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _tipoDispensacaoOptions
                  .map(
                    (e) => DropdownMenuItem<String?>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(growable: false),
              onChanged: controller.setTipoDispensacaoFilter,
            ),
          ),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<bool?>(
              key: ValueKey('ativo-${state.ativoFilter}'),
              isExpanded: true,
              initialValue: state.ativoFilter,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem<bool?>(value: null, child: Text('Todos')),
                DropdownMenuItem<bool?>(value: true, child: Text('Activos')),
                DropdownMenuItem<bool?>(value: false, child: Text('Inactivos')),
              ],
              onChanged: controller.setAtivoFilter,
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              key: ValueKey('sort-${state.sortBy}'),
              isExpanded: true,
              initialValue: _sortOptions.any((o) => o.key == state.sortBy)
                  ? state.sortBy
                  : 'nome',
              decoration: const InputDecoration(
                labelText: 'Ordenar por',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _sortOptions
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  controller.setSort(value, state.sortOrder);
                }
              },
            ),
          ),
          IconButton(
            tooltip: state.sortOrder == 'asc'
                ? 'Ordem ascendente'
                : 'Ordem descendente',
            onPressed: () => controller.setSort(
              state.sortBy,
              state.sortOrder == 'asc' ? 'desc' : 'asc',
            ),
            icon: Icon(
              state.sortOrder == 'asc'
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
            ),
          ),
          FilterChip(
            label: const Text('Incluir inactivos'),
            selected: state.includeInactive,
            onSelected: controller.setIncludeInactive,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          if (state.errorMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: s.sm),
              child: Text(
                state.errorMessage!,
                style: TextStyle(color: t.posDanger),
              ),
            ),
          if (pharmacyReportError(ref) != null)
            Padding(
              padding: EdgeInsets.only(bottom: s.sm),
              child: pharmacyReportError(ref),
            ),
          Expanded(
            child: !state.isInitialized && state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.items.isEmpty
                    ? const _ProductsEmptyState()
                    : EnterpriseDataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('PRODUTO')),
                          DataColumn(label: Text('CATEGORIA')),
                          DataColumn(label: Text('STOCK')),
                          DataColumn(label: Text('LOTES')),
                          DataColumn(label: Text('PRÓX. VALIDADE')),
                          DataColumn(label: Text('REGULAÇÃO')),
                          DataColumn(label: Text('ESTADO')),
                          DataColumn(label: Text('AÇÕES')),
                        ],
                        rowCount: state.items.length,
                        rowBuilder: (context, index) {
                          final product = state.items[index];
                          final isDeleting =
                              state.deletingProductIds.contains(product.id);
                          return DataRow(
                            onSelectChanged: (_) =>
                                _openDetails(context, product),
                            cells: [
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      product.nome,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: product.ativo
                                            ? t.textPrimary
                                            : t.textMuted,
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
                                  label: product.categoriaNome,
                                ),
                              ),
                              DataCell(
                                Text(
                                  _formatStock(product.estoqueAtual),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: product.estoqueAtual <=
                                            product.estoqueMinimo
                                        ? t.posDanger
                                        : t.textPrimary,
                                  ),
                                ),
                              ),
                              DataCell(Text('${product.numLotes}')),
                              DataCell(
                                Text(_formatDate(product.proximaValidade)),
                              ),
                              DataCell(
                                ProdutoRegulacaoBadges(product: product),
                              ),
                              DataCell(
                                _ProductStatusChip(isActive: product.ativo),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Detalhes',
                                      onPressed: () =>
                                          _openDetails(context, product),
                                      icon: const Icon(Icons.visibility_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Editar',
                                      onPressed: isDeleting
                                          ? null
                                          : () => _openEditDialog(
                                                context,
                                                ref,
                                                product,
                                              ),
                                      icon: const Icon(Icons.edit_outlined),
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
                                              child: CircularProgressIndicator(
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
            MovimentacoesPagination(
              page: state.page,
              pageSize: state.pageSize,
              hasMore: state.hasMore,
              isBusy: state.isLoading,
              onPrev: state.page > 1
                  ? () => controller.goToPage(state.page - 1)
                  : null,
              onNext: state.hasMore
                  ? () => controller.goToPage(state.page + 1)
                  : null,
              onPageSizeChanged: controller.setPageSize,
            ),
            if (state.totalCount != null)
              Padding(
                padding: EdgeInsets.only(top: s.xs),
                child: Text(
                  'Total: ${state.totalCount} produto(s)',
                  style: TextStyle(color: t.textMuted, fontSize: 12),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _formatStock(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$d/$m/$y';
  }

  Future<void> _openDetails(BuildContext context, Product product) async {
    final isMobile = PharmaScreenLayout.isMobile(context);

    if (isMobile) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (screenContext) => Scaffold(
            appBar: AppBar(title: Text(product.nome)),
            body: ProdutoDetailPanel(
              product: product,
              onClose: () => Navigator.of(screenContext).pop(),
            ),
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final t = context.pharmaTokens;
        final s = context.spacing;
        return Dialog(
          alignment: Alignment.centerRight,
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: s.md),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 560,
            decoration: BoxDecoration(
              color: t.bgPrimary,
              borderRadius: BorderRadius.circular(t.radiusXl),
              border: Border.all(color: t.border.withValues(alpha: 0.55)),
            ),
            child: ProdutoDetailPanel(
              product: product,
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showProdutoFormDialog(context);
    if (result == null || !context.mounted) return;

    try {
      await ref
          .read(masterProductListProvider.notifier)
          .createProduct(result.toPayload());
      if (context.mounted) {
        PharmaFeedback.success(context, 'Produto criado com sucesso');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.toString());
    }
  }

  Future<void> _openEditDialog(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final result = await showProdutoFormDialog(context, product: product);
    if (result == null || !context.mounted) return;

    try {
      await ref
          .read(masterProductListProvider.notifier)
          .updateProduct(product.id, result.toPayload());
      if (context.mounted) {
        PharmaFeedback.success(context, 'Produto actualizado com sucesso');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.toString());
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
          'Deseja excluir o produto «${product.nome}»?\n\n'
          'A operação seguirá o padrão actual do sistema.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
    );
    if (!context.mounted || confirmed != true) return;

    try {
      await ref.read(masterProductListProvider.notifier).deleteProduct(product.id);
      if (context.mounted) {
        PharmaFeedback.success(context, 'Produto excluído com sucesso');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.toString());
    }
  }
}

class _ProductsEmptyState extends StatelessWidget {
  const _ProductsEmptyState();

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
                'Ajuste os filtros ou crie um novo produto.',
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
