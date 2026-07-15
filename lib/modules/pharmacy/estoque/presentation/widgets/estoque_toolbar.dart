import 'package:flutter/material.dart';

import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../../shared/widgets/layout/enterprise_module_search_bar.dart';
import '../../../categories/domain/entities/category.dart';
import '../providers/estoque_provider.dart';

class EstoqueToolbar extends StatefulWidget {
  const EstoqueToolbar({
    super.key,
    required this.searchController,
    required this.state,
    required this.controller,
    required this.categories,
    required this.fornecedores,
    required this.onSearchChanged,
    required this.onOpenMobileFilters,
    this.trailingActions = const [],
  });

  final TextEditingController searchController;
  final EstoqueListState state;
  final EstoqueListController controller;
  final List<Category> categories;
  final List<({String id, String nome})> fornecedores;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenMobileFilters;
  final List<Widget> trailingActions;

  @override
  State<EstoqueToolbar> createState() => _EstoqueToolbarState();
}

class _EstoqueToolbarState extends State<EstoqueToolbar> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EstoqueToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController.removeListener(_onSearchChanged);
      widget.searchController.addListener(_onSearchChanged);
    }
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.pharmaScreen;
    if (screen == PharmaScreenSize.mobile) {
      return EnterpriseModuleSearchBar(
        controller: widget.searchController,
        hintText: 'Produto, código ou lote...',
        enabled: !widget.state.isLoading,
        onSubmitted: widget.onSearchChanged,
        onChanged: widget.onSearchChanged,
      );
    }

    final state = widget.state;

    return EnterpriseDesktopListToolbar(
      searchController: widget.searchController,
      searchHint: 'Pesquisar produto, código de barras ou lote...',
      isLoading: widget.state.isLoading,
      onSearchSubmitted: widget.onSearchChanged,
      hasFilters: widget.state.hasFilters,
      onClearFilters: widget.state.isLoading ? null : widget.controller.clearFilters,
      trailingActions: widget.trailingActions,
      filterWidgets: [
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String?>(
            key: ValueKey('estoque-cat-${state.categoriaId}'),
            isExpanded: true,
            initialValue: state.categoriaId,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
              ...widget.categories.map(
                (c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.nome)),
              ),
            ],
            onChanged: widget.state.isLoading
                ? null
                : widget.controller.setCategoriaFilter,
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String?>(
            key: ValueKey('estoque-forn-${state.fornecedorId}'),
            isExpanded: true,
            initialValue: state.fornecedorId,
            decoration: const InputDecoration(labelText: 'Fornecedor'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
              ...widget.fornecedores.map(
                (f) => DropdownMenuItem<String?>(value: f.id, child: Text(f.nome)),
              ),
            ],
            onChanged: widget.state.isLoading
                ? null
                : widget.controller.setFornecedorFilter,
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String?>(
            key: ValueKey('estoque-estado-${state.estadoSanitario}'),
            isExpanded: true,
            initialValue: state.estadoSanitario,
            decoration: const InputDecoration(labelText: 'Estado sanitário'),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('Todos')),
              DropdownMenuItem<String?>(value: 'VALIDO', child: Text('Válido')),
              DropdownMenuItem<String?>(value: 'EXPIRADO', child: Text('Expirado')),
              DropdownMenuItem<String?>(value: 'RECALL', child: Text('Recall')),
              DropdownMenuItem<String?>(value: 'QUARENTENA', child: Text('Quarentena')),
            ],
            onChanged: widget.state.isLoading
                ? null
                : widget.controller.setEstadoSanitarioFilter,
          ),
        ),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String?>(
            key: ValueKey('estoque-disp-${state.disponibilidade}'),
            isExpanded: true,
            initialValue: state.disponibilidade,
            decoration: const InputDecoration(labelText: 'Disponibilidade'),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('Todas')),
              DropdownMenuItem<String?>(value: 'DISPONIVEL', child: Text('Disponível')),
              DropdownMenuItem<String?>(value: 'BLOQUEADO', child: Text('Bloqueado')),
              DropdownMenuItem<String?>(value: 'INDISPONIVEL', child: Text('Indisponível')),
            ],
            onChanged: widget.state.isLoading
                ? null
                : widget.controller.setDisponibilidadeFilter,
          ),
        ),
      ],
    );
  }
}

class EstoqueMobileToolbar extends StatelessWidget {
  const EstoqueMobileToolbar({
    super.key,
    required this.searchController,
    required this.state,
    required this.controller,
    required this.onSearchChanged,
    required this.onOpenFilters,
    required this.reportAction,
  });

  final TextEditingController searchController;
  final EstoqueListState state;
  final EstoqueListController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;
  final Widget reportAction;

  @override
  Widget build(BuildContext context) {
    return EnterpriseMobileToolbar(
      searchController: searchController,
      searchHint: 'Produto, código ou lote...',
      enabled: !state.isLoading,
      isLoading: state.isLoading,
      hasFilters: state.hasFilters,
      reportAction: reportAction,
      onSearchSubmitted: onSearchChanged,
      onOpenFilters: onOpenFilters,
      onClearFilters: () async => controller.clearFilters(),
      onRefresh: controller.refreshCurrentPage,
    );
  }
}
