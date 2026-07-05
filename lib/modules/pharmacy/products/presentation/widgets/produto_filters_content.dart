import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../categories/domain/entities/category.dart';

/// Painel de filtros reutilizado no dropdown (desktop) e bottom sheet (mobile).
class ProdutoFiltersContent extends StatefulWidget {
  const ProdutoFiltersContent({
    super.key,
    required this.initialAtivo,
    required this.initialCategoriaId,
    required this.categories,
    required this.onApply,
    this.compact = false,
  });

  final bool? initialAtivo;
  final String? initialCategoriaId;
  final List<Category> categories;
  final void Function(bool? ativo, String? categoriaId) onApply;
  final bool compact;

  @override
  State<ProdutoFiltersContent> createState() => _ProdutoFiltersContentState();
}

class _ProdutoFiltersContentState extends State<ProdutoFiltersContent> {
  late bool? _ativo;
  late String? _categoriaId;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant ProdutoFiltersContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAtivo != widget.initialAtivo ||
        oldWidget.initialCategoriaId != widget.initialCategoriaId) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    _ativo = widget.initialAtivo;
    _categoriaId = widget.initialCategoriaId;
  }

  void _clearFilters() {
    setState(() {
      _ativo = null;
      _categoriaId = null;
    });
    widget.onApply(null, null);
  }

  void _apply() {
    widget.onApply(_ativo, _categoriaId);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<bool?>(
          key: ValueKey('produto-filter-status-$_ativo'),
          initialValue: _ativo,
          decoration: _dropdownDecoration(context, 'Status'),
          items: const [
            DropdownMenuItem<bool?>(value: null, child: Text('Todos')),
            DropdownMenuItem<bool?>(value: true, child: Text('Activos')),
            DropdownMenuItem<bool?>(value: false, child: Text('Inactivos')),
          ],
          onChanged: (value) => setState(() => _ativo = value),
        ),
        SizedBox(height: s.md),
        DropdownButtonFormField<String?>(
          key: ValueKey('produto-filter-categoria-$_categoriaId'),
          initialValue: _categoriaId,
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
          onChanged: (value) => setState(() => _categoriaId = value),
        ),
        SizedBox(height: s.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _clearFilters,
                child: const Text('Limpar'),
              ),
            ),
            SizedBox(width: s.md),
            Expanded(
              child: FilledButton(
                onPressed: _apply,
                child: Text(widget.compact ? 'Aplicar' : 'Aplicar filtros'),
              ),
            ),
          ],
        ),
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.radiusMd),
        borderSide: BorderSide(color: t.brandBlue, width: 2),
      ),
      isDense: true,
      contentPadding: t.density.inputPadding,
    );
  }
}
