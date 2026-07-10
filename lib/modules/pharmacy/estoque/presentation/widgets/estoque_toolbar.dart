import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
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
  });

  final TextEditingController searchController;
  final EstoqueListState state;
  final EstoqueListController controller;
  final List<Category> categories;
  final List<({String id, String nome})> fornecedores;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenMobileFilters;

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

    final t = context.pharmaTokens;
    final s = context.spacing;
    final state = widget.state;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: TextField(
              controller: widget.searchController,
              onChanged: widget.onSearchChanged,
              style: Theme.of(context).textTheme.erpBody.copyWith(color: t.textPrimary),
              decoration: InputDecoration(
                hintText: 'Pesquisar produto, código de barras ou lote...',
                hintStyle: Theme.of(context).textTheme.erpBody.copyWith(color: t.textMuted),
                prefixIcon: Icon(Icons.search_rounded, color: t.textMuted, size: t.iconSm),
                suffixIcon: widget.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: t.textMuted, size: t.iconSm),
                        onPressed: widget.state.isLoading
                            ? null
                            : () {
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
            ),
          ),
        ),
        SizedBox(width: s.md),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String?>(
            key: ValueKey('estoque-cat-${state.categoriaId}'),
            isExpanded: true,
            initialValue: state.categoriaId,
            decoration: _dropdownDecoration(context, 'Categoria'),
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
        SizedBox(width: s.md),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String?>(
            key: ValueKey('estoque-forn-${state.fornecedorId}'),
            isExpanded: true,
            initialValue: state.fornecedorId,
            decoration: _dropdownDecoration(context, 'Fornecedor'),
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
        SizedBox(width: s.md),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String?>(
            key: ValueKey('estoque-estado-${state.estadoSanitario}'),
            isExpanded: true,
            initialValue: state.estadoSanitario,
            decoration: _dropdownDecoration(context, 'Estado sanitário'),
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
        SizedBox(width: s.md),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String?>(
            key: ValueKey('estoque-disp-${state.disponibilidade}'),
            isExpanded: true,
            initialValue: state.disponibilidade,
            decoration: _dropdownDecoration(context, 'Disponibilidade'),
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
        if (state.hasFilters) ...[
          SizedBox(width: s.sm),
          TextButton.icon(
            onPressed: widget.state.isLoading ? null : widget.controller.clearFilters,
            icon: Icon(Icons.filter_alt_off_outlined, size: t.iconSm),
            label: const Text('Limpar'),
          ),
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
