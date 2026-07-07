import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/async_value_extensions.dart';
import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/responsive/responsive_builder.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../domain/entities/category.dart';
import '../../domain/fnm_categories.dart';
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
  List<Category> _accumulatedItems = [];

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
    final reportQuery = pharmacyReportQuery({
      if (_searchController.text.trim().isNotEmpty) 'q': _searchController.text.trim(),
    });

    ref.listen(categoryListProvider, (prev, next) {
      if (prev?.page != next.page ||
          prev?.query != next.query ||
          prev?.includeInactive != next.includeInactive) {
        if (next.page == 1) {
          _accumulatedItems = List.of(next.items);
        } else {
          final newItems = next.items
              .where((e) => !_accumulatedItems.any((a) => a.id == e.id))
              .toList();
          _accumulatedItems.addAll(newItems);
        }
      } else if (prev?.items != next.items && next.page == 1) {
        _accumulatedItems = List.of(next.items);
      }
    });

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return Scaffold(
          backgroundColor: t.bgPrimary,
          floatingActionButton: isMobile
              ? FloatingActionButton(
                  onPressed: state.isLoading ? null : () => _openForm(context),
                  child: const Icon(Icons.add),
                )
              : null,
          body: EnterpriseModuleHub(
            mobileKpisHorizontalScroll: true,
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
              if (!isMobile)
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
                  width: isMobile ? double.infinity : 280,
                  child: TextField(
                    controller: _searchController,
                    onChanged: controller.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar por nome...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: pharmacyReportActions(
                        ref: ref,
                        enabled: !state.isLoading,
                        path: ReportPaths.pharmacyCategories,
                        queryParameters: reportQuery,
                        isIconButton: true,
                      ).single,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('Mostrar inactivas'),
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
                    child: Text(
                      state.errorMessage!,
                      style: Theme.of(context).textTheme.erpBody.copyWith(color: t.posDanger),
                    ),
                  ),
                Expanded(
                  child: isMobile
                      ? _CategoryMobileList(
                          items: _accumulatedItems,
                          hasMore: state.hasMore,
                          isLoading: state.isLoading,
                          onLoadMore: () => controller.goToPage(state.page + 1),
                          onEdit: (category) => _openForm(context, category: category),
                          onDelete: (category) => _confirmDelete(context, category),
                        )
                      : EnterpriseDataTable(
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
                                DataCell(Text(fnmCategoryLabel(item.nome))),
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
                if (!isMobile) _PaginationBar(state: state, onPage: controller.goToPage),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openForm(BuildContext context, {Category? category}) async {
    final title = Text(
      category == null ? 'Nova categoria' : 'Editar categoria',
    );
    final routeSettings = RouteSettings(
      name: category == null
          ? '/categorias/nova'
          : '/categorias/${category.id}/editar',
    );
    final result = AdaptiveNavigator.isMobile(context)
        ? await AdaptiveNavigator.open<Map<String, dynamic>>(
            context: context,
            routeSettings: routeSettings,
            builder: (pageContext) => Scaffold(
              appBar: AppBar(title: title),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _CategoryFormDialog(
                    category: category,
                    embedded: true,
                    pinnedFooter: true,
                  ),
                ),
              ),
            ),
          )
        : await AdaptiveNavigator.openEmbeddedForm<Map<String, dynamic>>(
            context: context,
            title: title,
            routeSettings: routeSettings,
            formBuilder: (ctx, {required embedded}) =>
                _CategoryFormDialog(category: category, embedded: embedded),
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
  const _CategoryFormDialog({
    this.category,
    this.embedded = false,
    this.pinnedFooter = false,
  });
  final Category? category;
  final bool embedded;
  final bool pinnedFooter;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricao;
  late String? _nomeSelecionado;
  late bool _ativo;

  @override
  void initState() {
    super.initState();
    _descricao = TextEditingController(text: widget.category?.descricao ?? '');
    _nomeSelecionado = widget.category?.nome;
    _ativo = widget.category?.ativo ?? true;
  }

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nomeOptions = <String>[
      ...kFnmCategories,
      if (_nomeSelecionado != null &&
          _nomeSelecionado!.trim().isNotEmpty &&
          !kFnmCategories.contains(_nomeSelecionado)) _nomeSelecionado!,
    ];

    final formFields = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: nomeOptions.contains(_nomeSelecionado)
              ? _nomeSelecionado
              : null,
          decoration: const InputDecoration(labelText: 'Categoria FNM *'),
          items: nomeOptions
              .map(
                (nome) => DropdownMenuItem<String>(
                  value: nome,
                  child: Text(fnmCategoryLabel(nome)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() => _nomeSelecionado = value),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Categoria obrigatória' : null,
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
    );

    final actions = [
      TextButton(
        onPressed: () => AdaptiveNavigator.cancel(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          AdaptiveNavigator.complete(context, {
            'nome': _nomeSelecionado!.trim(),
            'descricao': _descricao.text.trim().isEmpty
                ? null
                : _descricao.text.trim(),
            'ativo': _ativo,
          });
        },
        child: const Text('Guardar'),
      ),
    ];

    final form = Form(
      key: _formKey,
      child: widget.pinnedFooter
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: formFields,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            )
          : formFields,
    );

    if (widget.embedded) {
      if (widget.pinnedFooter) {
        return form;
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          form,
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: Text(widget.category == null ? 'Nova categoria' : 'Editar categoria'),
      content: form,
      actions: actions,
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
        style: Theme.of(context).textTheme.erpCaption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _CategoryMobileList extends StatefulWidget {
  const _CategoryMobileList({
    required this.items,
    required this.hasMore,
    required this.isLoading,
    required this.onLoadMore,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Category> items;
  final bool hasMore;
  final bool isLoading;
  final VoidCallback onLoadMore;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;

  @override
  State<_CategoryMobileList> createState() => _CategoryMobileListState();
}

class _CategoryMobileListState extends State<_CategoryMobileList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoading) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    if (widget.items.isEmpty && !widget.isLoading) {
      return Center(
        child: Text(
          'Nenhuma categoria encontrada',
          style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: widget.items.length + 1,
      separatorBuilder: (_, index) {
        if (index >= widget.items.length - 1) {
          return const SizedBox.shrink();
        }
        return const EnterpriseListDivider();
      },
      itemBuilder: (context, index) {
        if (index == widget.items.length) {
          if (widget.isLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          if (!widget.hasMore && widget.items.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Fim da lista',
                  style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final category = widget.items[index];
        return _CategoryMobileCard(
          category: category,
          onTap: () => widget.onEdit(category),
          onEdit: () => widget.onEdit(category),
          onDelete: () => widget.onDelete(category),
        );
      },
    );
  }
}

class _CategoryMobileCard extends StatelessWidget {
  const _CategoryMobileCard({
    required this.category,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final descricao = category.descricao?.trim();

    return EnterpriseListCard(
      title: fnmCategoryLabel(category.nome),
      subtitle: descricao != null && descricao.isNotEmpty ? descricao : null,
      leading: Icons.category_outlined,
      chip: EnterpriseStatusChip(
        label: category.ativo ? 'Activa' : 'Inactiva',
        color: category.ativo ? t.brandGreen : t.textMuted,
      ),
      trailingMeta: EnterpriseListCardMeta(
        label: 'Produtos: ${category.productCount}',
        alignEnd: true,
        emphasized: true,
      ),
      onTap: onTap,
      actions: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: t.minTouchTarget * 0.6,
          minHeight: t.minTouchTarget * 0.6,
        ),
        icon: Icon(Icons.more_vert, size: t.iconSm, color: t.textMuted),
        onSelected: (action) {
          switch (action) {
            case 'editar':
              onEdit();
              break;
            case 'excluir':
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'editar', child: Text('Editar')),
          PopupMenuItem(value: 'excluir', child: Text('Excluir')),
        ],
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
