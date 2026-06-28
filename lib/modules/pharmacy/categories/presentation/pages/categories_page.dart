import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/async_value_extensions.dart';
import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../domain/entities/category.dart';
import '../providers/category_provider.dart';
import '../providers/category_stats_provider.dart';
import '../../../presentation/widgets/pharmacy_report_exports.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryListProvider);
    final controller = ref.read(categoryListProvider.notifier);
    final statsAsync = ref.watch(categoryStatsProvider);
    final t = context.pharmaTokens;
    final s = context.spacing;
    final reportQuery = <String, dynamic>{
      if (state.query.isNotEmpty) 'q': state.query,
      if (state.includeInactive) 'includeInactive': true,
    };

    return EnterpriseModuleHub(
      title: 'Categorias',
      subtitle: 'Gestão de categorias de produtos com contagem vinculada.',
      tag: 'Farmácia',
      kpis: statsAsync.valueOrNull == null
          ? null
          : [
              EnterpriseStatCard(
                title: 'Categorias',
                value: '${statsAsync.valueOrNull?['totalCategorias'] ?? 0}',
                icon: Icons.category_outlined,
              ),
              EnterpriseStatCard(
                title: 'Produtos',
                value: '${statsAsync.valueOrNull?['totalProdutos'] ?? 0}',
                icon: Icons.inventory_2_outlined,
              ),
              EnterpriseStatCard(
                title: 'Activas/Inactivas',
                value:
                    '${statsAsync.valueOrNull?['categoriasActivas'] ?? 0}/${statsAsync.valueOrNull?['categoriasInactivas'] ?? 0}',
                icon: Icons.toggle_on_outlined,
              ),
              EnterpriseStatCard(
                title: 'Stock',
                value: '${statsAsync.valueOrNull?['stockDisponivel'] ?? 0}',
                icon: Icons.stacked_bar_chart_outlined,
              ),
            ],
      actions: [
        ...pharmacyReportActions(
          ref: ref,
          enabled: !state.isLoading,
          path: ReportPaths.pharmacyCategories,
          queryParameters: reportQuery,
        ),
        FilledButton.icon(
          onPressed: state.isLoading ? null : () => _openForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Nova categoria'),
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
                hintText: 'Pesquisar por nome...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          FilterChip(
            label: const Text('Incluir inactivas'),
            selected: state.includeInactive,
            onSelected: controller.setIncludeInactive,
          ),
        ],
      ),
      child: Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          if (state.errorMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: s.sm),
              child: Text(state.errorMessage!, style: TextStyle(color: t.posDanger)),
            ),
          if (pharmacyReportError(ref) != null)
            Padding(
              padding: EdgeInsets.only(bottom: s.sm),
              child: pharmacyReportError(ref),
            ),
          Expanded(
            child: EnterpriseDataTable(
              columns: const [
                DataColumn(label: Text('NOME')),
                DataColumn(label: Text('DESCRIÇÃO')),
                DataColumn(label: Text('PRODUTOS')),
                DataColumn(label: Text('ESTADO')),
                DataColumn(label: Text('AÇÕES')),
              ],
              rowCount: state.items.length,
              rowBuilder: (context, index) {
                final item = state.items[index];
                return DataRow(
                  cells: [
                    DataCell(Text(item.nome)),
                    DataCell(Text(item.descricao ?? '—')),
                    DataCell(Text('${item.productCount}')),
                    DataCell(_StatusChip(ativo: item.ativo)),
                    DataCell(Row(
                      children: [
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () => _openForm(context, category: item),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Excluir',
                          onPressed: () => _confirmDelete(context, item),
                          icon: Icon(Icons.delete_outline, color: t.posDanger),
                        ),
                      ],
                    )),
                  ],
                );
              },
            ),
          ),
          _PaginationBar(state: state, onPage: controller.goToPage),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Category? category}) async {
    final result = await showPharmaResponsiveDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _CategoryFormDialog(category: category),
    );
    if (result == null || !context.mounted) return;
    final notifier = ref.read(categoryListProvider.notifier);
    try {
      if (category == null) {
        await notifier.create(result);
        if (!context.mounted) return;
        PharmaFeedback.success(context, 'Categoria criada.');
      } else {
        await notifier.update(category.id, result);
        if (!context.mounted) return;
        PharmaFeedback.success(context, 'Categoria actualizada.');
      }
    } on ApiFailure catch (e) {
      if (!context.mounted) return;
      PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (!context.mounted) return;
      PharmaFeedback.error(context, e.toString());
    }
  }

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Excluir categoria',
      message:
          'A categoria «${category.nome}» será desactivada. Não é possível excluir se existirem produtos vinculados.',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(categoryListProvider.notifier).delete(category.id);
      if (!context.mounted) return;
      PharmaFeedback.success(context, 'Categoria excluída.');
    } on ApiFailure catch (e) {
      if (!context.mounted) return;
      PharmaFeedback.error(context, e.message);
    }
  }
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({this.category});
  final Category? category;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _descricao;
  late bool _ativo;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.category?.nome ?? '');
    _descricao = TextEditingController(text: widget.category?.descricao ?? '');
    _ativo = widget.category?.ativo ?? true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PharmaResponsiveDialog(
      title: Text(widget.category == null ? 'Nova categoria' : 'Editar categoria'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nome obrigatório' : null,
            ),
            TextFormField(
              controller: _descricao,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 2,
            ),
            SwitchListTile(
              title: const Text('Activa'),
              value: _ativo,
              onChanged: (v) => setState(() => _ativo = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'nome': _nome.text.trim(),
              'descricao': _descricao.text.trim().isEmpty
                  ? null
                  : _descricao.text.trim(),
              'ativo': _ativo,
            });
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.ativo});
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final color = ativo ? t.brandGreen : t.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ativo ? 'Activa' : 'Inactiva',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.state, required this.onPage});
  final CategoryListState state;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final start = state.items.isEmpty ? 0 : (state.page - 1) * state.pageSize + 1;
    final end = (state.page - 1) * state.pageSize + state.items.length;
    return Row(
      children: [
        Text('Mostrando $start–$end • Página ${state.page}'),
        const Spacer(),
        IconButton(
          onPressed: state.page > 1 ? () => onPage(state.page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          onPressed: state.hasMore ? () => onPage(state.page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
