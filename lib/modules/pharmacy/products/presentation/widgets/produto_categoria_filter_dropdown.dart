import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../categories/presentation/providers/category_provider.dart';

/// Dropdown de categorias FNM (API) para filtros de catálogo.
class ProdutoCategoriaFilterDropdown extends ConsumerWidget {
  const ProdutoCategoriaFilterDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 260,
    this.enabled = true,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final double? width;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return SizedBox(
      width: width,
      child: categoriesAsync.when(
        loading: () => DropdownButtonFormField<String?>(
          initialValue: value,
          decoration: _decoration(context, t, 'Categoria'),
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('Todas')),
          ],
          onChanged: null,
        ),
        error: (_, __) => DropdownButtonFormField<String?>(
          initialValue: value,
          decoration: _decoration(context, t, 'Categoria'),
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('Todas')),
          ],
          onChanged: enabled ? onChanged : null,

        ),
        data: (categories) => DropdownButtonFormField<String?>(
          initialValue: value != null && categories.any((c) => c.id == value)
              ? value
              : null,
          decoration: _decoration(context, t, 'Categoria'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todas'),
            ),
            ...categories.map(
              (cat) => DropdownMenuItem<String?>(
                value: cat.id,
                child: Text(
                  cat.nome,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  InputDecoration _decoration(
    BuildContext context,
    PharmaTokens t,
    String label,
  ) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.radiusMd),
        borderSide: BorderSide(color: t.border),
      ),
      filled: true,
      fillColor: t.bgPrimary.withValues(alpha: 0.5),
    );
  }
}
