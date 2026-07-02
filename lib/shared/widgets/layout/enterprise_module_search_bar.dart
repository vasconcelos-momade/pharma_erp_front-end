import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// Campo de pesquisa padronizado para módulos enterprise (mobile e desktop).
class EnterpriseModuleSearchBar extends StatefulWidget {
  const EnterpriseModuleSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
    this.enabled = true,
    this.onChanged,
    this.maxWidth,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final double? maxWidth;

  @override
  State<EnterpriseModuleSearchBar> createState() => _EnterpriseModuleSearchBarState();
}

class _EnterpriseModuleSearchBarState extends State<EnterpriseModuleSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EnterpriseModuleSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final field = TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: t.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: t.textMuted),
        prefixIcon: Icon(Icons.search_rounded, color: t.textMuted, size: t.iconSm),
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear_rounded, color: t.textMuted, size: t.iconSm),
                onPressed: widget.enabled
                    ? () {
                        widget.controller.clear();
                        widget.onSubmitted('');
                      }
                    : null,
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

    if (widget.maxWidth == null) return field;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth!),
      child: field,
    );
  }
}

InputDecoration enterpriseDropdownDecoration(BuildContext context, String label) {
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
