import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/auth_session_notifier.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/pharma_surface.dart';
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
    final authReady = ref.watch(
      authSessionProvider.select(
        (session) => !session.isBootstrapping && session.hasTenantContext,
      ),
    );
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final textTheme = Theme.of(context).textTheme;

    DropdownMenuItem<String?> allItem() => DropdownMenuItem<String?>(
          value: null,
          child: Text('Todas', style: textTheme.erpSelectValue),
        );

    Widget buildDropdown({
      required List<DropdownMenuItem<String?>> items,
      required ValueChanged<String?>? onChanged,
      String? currentValue,
    }) {
      final t = context.pharmaTokens;
      final scheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return DropdownButtonFormField<String?>(
        key: ValueKey<Object?>('$currentValue-${items.length}'),
        value: currentValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Categoria',
          isDense: true,
          contentPadding: t.density.inputPadding,
          labelStyle: textTheme.erpSelectLabel.copyWith(color: t.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusMd),
            borderSide: BorderSide(
              color: scheme.outline.withValues(alpha: isDark ? 0.6 : 0.85),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusMd),
            borderSide: BorderSide(
              color: scheme.outline.withValues(alpha: isDark ? 0.6 : 0.85),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusMd),
            borderSide: BorderSide(
              color: scheme.primary,
            ),
          ),
        ),
        dropdownColor: scheme.surfaceContainerHighest,
        style: textTheme.erpSelectValue.copyWith(color: t.textPrimary),
        items: items,
        onChanged: onChanged,
        menuMaxHeight: 400,
      );
    }

    return SizedBox(
      width: width,
      child: !authReady || categoriesAsync.isLoading
          ? buildDropdown(
              currentValue: value,
              items: [allItem()],
              onChanged: null,
            )
          : categoriesAsync.when(
        loading: () => buildDropdown(
          currentValue: value,
          items: [allItem()],
          onChanged: null,
        ),
        error: (_, _) => buildDropdown(
          currentValue: value,
          items: [allItem()],
          onChanged: enabled ? onChanged : null,
        ),
        data: (categories) => buildDropdown(
          currentValue: value != null && categories.any((c) => c.id == value)
              ? value
              : null,
          items: [
            allItem(),
            ...categories.map(
              (cat) => DropdownMenuItem<String?>(
                value: cat.id,
                child: Text(
                  cat.nome,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.erpSelectValue,
                ),
              ),
            ),
          ],
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}
