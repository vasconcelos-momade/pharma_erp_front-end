import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../categories/domain/entities/category.dart';

/// Painel de filtros reutilizado no dropdown (desktop) e bottom sheet (mobile).
class ProdutoFiltersContent extends StatelessWidget {
  const ProdutoFiltersContent({
    super.key,
    required this.ativo,
    required this.categoriaId,
    required this.categories,
    required this.onAtivoChanged,
    required this.onCategoriaChanged,
    required this.onClear,
    required this.onApply,
    this.compact = false,
    this.showActions = true,
  });

  final bool? ativo;
  final String? categoriaId;
  final List<Category> categories;
  final ValueChanged<bool?> onAtivoChanged;
  final ValueChanged<String?> onCategoriaChanged;
  final VoidCallback onClear;
  final void Function(bool? ativo, String? categoriaId) onApply;
  final bool compact;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<bool?>(
          key: ValueKey('produto-filter-status-$ativo'),
          initialValue: ativo,
          isExpanded: true,
          decoration: _dropdownDecoration(context, 'Status'),
          items: const [
            DropdownMenuItem<bool?>(value: null, child: Text('Todos')),
            DropdownMenuItem<bool?>(value: true, child: Text('Activos')),
            DropdownMenuItem<bool?>(value: false, child: Text('Inactivos')),
          ],
          onChanged: onAtivoChanged,
        ),
        SizedBox(height: s.md),
        DropdownButtonFormField<String?>(
          key: ValueKey('produto-filter-categoria-$categoriaId'),
          initialValue: categoriaId,
          isExpanded: true,
          menuMaxHeight: 400,
          decoration: _dropdownDecoration(context, 'Categoria'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
            ...categories.map(
              (cat) => DropdownMenuItem<String?>(
                value: cat.id,
                child: Text(cat.nome, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onCategoriaChanged,
        ),
        if (showActions) ...[
          SizedBox(height: s.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClear,
                  child: const Text('Limpar'),
                ),
              ),
              SizedBox(width: s.md),
              Expanded(
                child: FilledButton(
                  onPressed: () => onApply(ativo, categoriaId),
                  child: Text(compact ? 'Aplicar' : 'Aplicar filtros'),
                ),
              ),
            ],
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.radiusMd),
        borderSide: BorderSide(color: t.brandBlue, width: 2),
      ),
      isDense: true,
      contentPadding: t.density.inputPadding,
    );
  }
}
