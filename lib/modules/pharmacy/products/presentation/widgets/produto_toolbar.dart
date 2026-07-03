import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../../shared/widgets/layout/enterprise_module_search_bar.dart';
import '../../../categories/domain/entities/category.dart';
import '../providers/product_provider.dart';

/// Barra de pesquisa e filtros adaptativa (dropdowns inline em desktop/web).
class ProdutoToolbar extends StatefulWidget {
  const ProdutoToolbar({
    super.key,
    required this.searchController,
    required this.state,
    required this.controller,
    required this.categories,
    required this.onSearchChanged,
    required this.onOpenMobileFilters,
  });

  final TextEditingController searchController;
  final MasterProductListState state;
  final MasterProductListController controller;
  final List<Category> categories;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenMobileFilters;

  @override
  State<ProdutoToolbar> createState() => _ProdutoToolbarState();
}

class _ProdutoToolbarState extends State<ProdutoToolbar> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchControllerChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchControllerChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProdutoToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController.removeListener(_onSearchControllerChanged);
      widget.searchController.addListener(_onSearchControllerChanged);
    }
  }

  void _onSearchControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.pharmaScreen;
    final isWide = screen != PharmaScreenSize.mobile;
    final state = widget.state;
    final controller = widget.controller;

    if (!isWide) {
      return EnterpriseModuleSearchBar(
        controller: widget.searchController,
        hintText: 'Pesquisar produto...',
        enabled: !state.isLoading,
        onSubmitted: widget.onSearchChanged,
        onChanged: widget.onSearchChanged,
      );
    }

    final statusDropdown = DropdownButtonFormField<bool?>(
      isExpanded: true,
      initialValue: state.ativoFilter,
      decoration: enterpriseDropdownDecoration(context, 'Status'),
      items: const [
        DropdownMenuItem<bool?>(value: null, child: Text('Todos')),
        DropdownMenuItem<bool?>(value: true, child: Text('Activos')),
        DropdownMenuItem<bool?>(value: false, child: Text('Inactivos')),
      ],
      onChanged: state.isLoading ? null : controller.setAtivoFilter,
    );

    final categoryDropdown = DropdownButtonFormField<String?>(
      isExpanded: true,
      initialValue: state.categoriaId,
      decoration: enterpriseDropdownDecoration(context, 'Categoria'),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
        ...widget.categories.map(
          (cat) => DropdownMenuItem<String?>(
            value: cat.id,
            child: Text(cat.nome, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: state.isLoading ? null : controller.setCategoriaIdFilter,
    );

    return EnterpriseDesktopListToolbar(
      searchController: widget.searchController,
      searchHint: 'Pesquisar produto...',
      isLoading: state.isLoading,
      onSearchSubmitted: widget.onSearchChanged,
      hasFilters: state.hasFilters,
      onClearFilters: controller.clearFilters,
      filterWidgets: [
        SizedBox(
          width: 168,
          child: statusDropdown,
        ),
        SizedBox(
          width: 200,
          child: categoryDropdown,
        ),
      ],
    );
  }
}

/// Toolbar mobile completa para a página de produtos.
class ProdutoMobileToolbar extends StatelessWidget {
  const ProdutoMobileToolbar({
    super.key,
    required this.searchController,
    required this.state,
    required this.controller,
    required this.onSearchChanged,
    required this.onOpenFilters,
    required this.reportAction,
  });

  final TextEditingController searchController;
  final MasterProductListState state;
  final MasterProductListController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;
  final Widget reportAction;

  @override
  Widget build(BuildContext context) {
    return EnterpriseMobileToolbar(
      searchController: searchController,
      searchHint: 'Pesquisar produto...',
      enabled: !state.isLoading,
      isLoading: state.isLoading,
      hasFilters: state.hasFilters,
      onSearchSubmitted: onSearchChanged,
      onOpenFilters: onOpenFilters,
      onRefresh: controller.refreshCurrentPage,
      onClearFilters: state.hasFilters
          ? () async => controller.clearFilters()
          : null,
      reportAction: reportAction,
    );
  }
}
