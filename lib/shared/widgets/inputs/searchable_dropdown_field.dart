import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';

/// Dropdown com pesquisa integrada (demo UX — ligar a async repository depois).
class SearchableDropdownField<T> extends StatefulWidget {
  const SearchableDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.display,
    this.onChanged,
    this.hintText = 'Pesquisar…',
  });

  final String label;
  final List<T> items;
  final String Function(T value) display;
  final ValueChanged<T?>? onChanged;
  final String hintText;

  @override
  State<SearchableDropdownField<T>> createState() => _SearchableDropdownFieldState<T>();
}

class _SearchableDropdownFieldState<T> extends State<SearchableDropdownField<T>> {
  T? _selected;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final filtered = widget.items
        .where((e) => widget.display(e).toLowerCase().contains(_search.text.trim().toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.textMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: () async {
            _search.clear();
            final picked = await showDialog<T>(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  backgroundColor: t.card,
                  title: Text('Seleccionar', style: TextStyle(color: t.textPrimary)),
                  content: SizedBox(
                    width: 420,
                    height: 360,
                    child: StatefulBuilder(
                      builder: (context, setLocal) {
                        return Column(
                          children: [
                            TextField(
                              controller: _search,
                              onChanged: (_) => setLocal(() {}),
                              decoration: InputDecoration(hintText: widget.hintText),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Expanded(
                              child: ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (c, i) {
                                  final item = filtered[i];
                                  return ListTile(
                                    title: Text(widget.display(item), style: TextStyle(color: t.textPrimary)),
                                    onTap: () => Navigator.pop(ctx, item),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            );
            if (picked != null) {
              setState(() => _selected = picked);
              widget.onChanged?.call(picked);
            }
          },
          borderRadius: BorderRadius.circular(t.radiusMd),
          child: InputDecorator(
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.arrow_drop_down_rounded),
            ),
            child: Text(
              _selected == null ? 'Toque para escolher' : widget.display(_selected as T),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _selected == null ? t.textMuted : t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
