import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../domain/entities/fornecedor.dart';
import '../providers/fornecedor_list_provider.dart';
import '../widgets/fornecedor_form_dialog.dart';

class FornecedoresPage extends ConsumerStatefulWidget {
  const FornecedoresPage({super.key});

  @override
  ConsumerState<FornecedoresPage> createState() => _FornecedoresPageState();
}

class _FornecedoresPageState extends ConsumerState<FornecedoresPage> {
  final _searchController = TextEditingController();
  List<FornecedorDetalhe> _accumulatedItems = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final t = context.pharmaTokens;
    final state = ref.watch(fornecedorListProvider);
    final controller = ref.read(fornecedorListProvider.notifier);

    if (_searchController.text != state.query) {
      _searchController.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    ref.listen(fornecedorListProvider, (prev, next) {
      if (prev?.page != next.page || prev?.query != next.query) {
        if (next.page == 1) {
          _accumulatedItems = List.of(next.items);
        } else {
          _accumulatedItems.addAll(
            next.items.where((e) => !_accumulatedItems.any((a) => a.id == e.id)),
          );
        }
      } else if (prev?.items != next.items && next.page == 1) {
        _accumulatedItems = List.of(next.items);
      }
    });

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;
        final isDesktop = constraints.isDesktopOrWider;

        return Scaffold(
          backgroundColor: t.bgPrimary,
          floatingActionButton: isMobile
              ? FloatingActionButton(
                  onPressed: state.isLoading ? null : () => _openCreate(context),
                  child: const Icon(Icons.add),
                )
              : null,
          body: EnterpriseModuleHub(
            title: 'Fornecedores',
            subtitle: 'Gestão de fornecedores e contactos comerciais.',
            tag: 'Stock',
            actions: isMobile
                ? null
                : [
                    OutlinedButton.icon(
                      onPressed: state.isLoading ? null : controller.refreshCurrentPage,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Atualizar'),
                    ),
                    FilledButton.icon(
                      onPressed: state.isLoading ? null : () => _openCreate(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Novo fornecedor'),
                    ),
                  ],
            child: Column(
              children: [
                if (state.errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: s.sm),
                    child: Text(
                      state.errorMessage!,
                      style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                            color: t.posDanger,
                          ),
                    ),
                  ),
                Expanded(
                  child: isMobile
                      ? EnterpriseMobileScrollList(
                          stickyHeader: EnterpriseMobileToolbar(
                            searchController: _searchController,
                            searchHint: 'Nome, NUIT, email...',
                            enabled: !state.isLoading,
                            isLoading: state.isLoading,
                            hasFilters: state.query.isNotEmpty,
                            showFiltersButton: false,
                            onSearchSubmitted: controller.onSearchChanged,
                            onOpenFilters: () {},
                            onClearFilters: () async {
                              controller.onSearchChanged('');
                            },
                            onRefresh: controller.refreshCurrentPage,
                          ),
                          itemCount: _accumulatedItems.length,
                          itemBuilder: (context, index) {
                            final item = _accumulatedItems[index];
                            return _FornecedorCard(
                              fornecedor: item,
                              onEdit: () => _openEdit(context, item),
                              onDelete: () => _confirmDelete(context, item),
                            );
                          },
                          hasMore: state.hasMore,
                          isLoading: state.isLoading,
                          onLoadMore: () => controller.goToPage(state.page + 1),
                          emptyMessage: 'Nenhum fornecedor encontrado',
                          totalCount: state.totalCount,
                        )
                      : EnterpriseDataTable(
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('NOME')),
                            DataColumn(label: Text('NUIT')),
                            DataColumn(label: Text('TELEFONE')),
                            DataColumn(label: Text('EMAIL')),
                            DataColumn(label: Text('CIDADE')),
                            DataColumn(label: Text('AÇÕES')),
                          ],
                          rowCount: state.items.length,
                          rowBuilder: (context, index) {
                            final item = state.items[index];
                            return DataRow(
                              cells: [
                                DataCell(Text(item.nome)),
                                DataCell(Text(item.nuit ?? '—')),
                                DataCell(Text(item.telefone ?? '—')),
                                DataCell(Text(item.email ?? '—')),
                                DataCell(Text(item.cidade ?? '—')),
                                DataCell(
                                  PopupMenuButton<String>(
                                    onSelected: (action) {
                                      if (action == 'editar') {
                                        _openEdit(context, item);
                                      } else if (action == 'excluir') {
                                        _confirmDelete(context, item);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                                      PopupMenuItem(value: 'excluir', child: Text('Eliminar')),
                                    ],
                                    icon: const Icon(Icons.more_vert),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                if (isDesktop && state.totalCount != null)
                  EnterprisePagination(
                    page: state.page,
                    pageSize: state.pageSize,
                    totalCount: state.totalCount!,
                    itemLabel: 'fornecedores',
                    onPageChanged: controller.goToPage,
                    onPageSizeChanged: controller.setPageSize,
                    isBusy: state.isLoading,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    final result = await showFornecedorFormDialog(context);
    if (result == null || !context.mounted) return;
    try {
      await ref.read(fornecedorListProvider.notifier).create(result.payload);
      if (context.mounted) PharmaFeedback.success(context, 'Fornecedor criado');
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    }
  }

  Future<void> _openEdit(BuildContext context, FornecedorDetalhe item) async {
    final result = await showFornecedorFormDialog(context, fornecedor: item);
    if (result == null || !context.mounted) return;
    try {
      await ref.read(fornecedorListProvider.notifier).update(item.id, result.payload);
      if (context.mounted) PharmaFeedback.success(context, 'Fornecedor actualizado');
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    }
  }

  Future<void> _confirmDelete(BuildContext context, FornecedorDetalhe item) async {
    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Eliminar fornecedor',
      message: 'Deseja eliminar «${item.nome}»?',
      confirmText: 'Eliminar',
      destructive: true,
    );
    if (!context.mounted || confirmed != true) return;
    try {
      await ref.read(fornecedorListProvider.notifier).delete(item.id);
      if (context.mounted) PharmaFeedback.success(context, 'Fornecedor eliminado');
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    }
  }
}

class _FornecedorCard extends StatelessWidget {
  const _FornecedorCard({
    required this.fornecedor,
    required this.onEdit,
    required this.onDelete,
  });

  final FornecedorDetalhe fornecedor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Card(
      margin: EdgeInsets.only(bottom: s.sm),
      child: ListTile(
        title: Text(fornecedor.nome),
        subtitle: Text(
          [
            if (fornecedor.nuit != null) 'NUIT: ${fornecedor.nuit}',
            if (fornecedor.telefone != null) fornecedor.telefone,
            if (fornecedor.email != null) fornecedor.email,
          ].whereType<String>().join(' • '),
          style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'editar') onEdit();
            if (action == 'excluir') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'editar', child: Text('Editar')),
            PopupMenuItem(value: 'excluir', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}
