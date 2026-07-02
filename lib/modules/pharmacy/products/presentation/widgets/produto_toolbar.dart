import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
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
    final t = context.pharmaTokens;
    final s = context.spacing;
    final screen = context.pharmaScreen;
    final isWide = screen != PharmaScreenSize.mobile;
    final state = widget.state;
    final controller = widget.controller;

    final searchField = TextField(
      controller: widget.searchController,
      onChanged: widget.onSearchChanged,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: t.textPrimary),
      decoration: InputDecoration(
        hintText: 'Pesquisar produto...',
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: t.textMuted),
        prefixIcon: Icon(Icons.search_rounded, color: t.textMuted, size: t.iconSm),
        suffixIcon: widget.searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear_rounded, color: t.textMuted, size: t.iconSm),
                onPressed: () {
                  widget.searchController.clear();
                  widget.onSearchChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: t.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
          borderSide: BorderSide(color: t.border.withValues(alpha: 0.45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
          borderSide: BorderSide(color: t.border.withValues(alpha: 0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
          borderSide: BorderSide(color: t.brandBlue, width: 2),
        ),
        isDense: true,
        contentPadding: t.density.inputPadding,
      ),
    );

    if (!isWide) {
      return searchField;
    }

    final statusDropdown = DropdownButtonFormField<bool?>(
      initialValue: state.ativoFilter,
      decoration: _dropdownDecoration(context, 'Status'),
      items: const [
        DropdownMenuItem<bool?>(value: null, child: Text('Todos')),
        DropdownMenuItem<bool?>(value: true, child: Text('Activos')),
        DropdownMenuItem<bool?>(value: false, child: Text('Inactivos')),
      ],
      onChanged: state.isLoading ? null : controller.setAtivoFilter,
    );

    final categoryDropdown = DropdownButtonFormField<String?>(
      initialValue: state.categoriaId,
      decoration: _dropdownDecoration(context, 'Categoria'),
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

    final clearButton = state.hasFilters
        ? TextButton.icon(
            onPressed: state.isLoading ? null : controller.clearFilters,
            icon: Icon(Icons.filter_alt_off_outlined, size: t.iconSm),
            label: const Text('Limpar'),
          )
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: searchField,
          ),
        ),
        SizedBox(width: s.md),
        SizedBox(width: 148, child: statusDropdown),
        SizedBox(width: s.md),
        SizedBox(width: 180, child: categoryDropdown),
        if (clearButton != null) ...[
          SizedBox(width: s.sm),
          clearButton,
        ],
      ],
    );
  }

  InputDecoration _dropdownDecoration(BuildContext context, String label) {
    final t = context.pharmaTokens;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: t.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.radiusMd),
        borderSide: BorderSide(color: t.border.withValues(alpha: 0.45)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.radiusMd),
        borderSide: BorderSide(color: t.border.withValues(alpha: 0.45)),
      ),
      isDense: true,
      contentPadding: t.density.inputPadding,
    );
  }
}
