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
      return PharmaInstantDropdown<String?>(
        label: 'Categoria',
        width: width,
        value: currentValue,
        onChanged: onChanged,
        items: items,
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
