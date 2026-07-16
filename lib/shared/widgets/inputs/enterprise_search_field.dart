import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import '../../responsive/pharma_screen_layout.dart';

/// Campo de pesquisa enterprise unificado (tabelas/listagens/toolbars/dialogs).
///
/// Regras de largura (prompt):
/// - Desktop: maxWidth 320
/// - Tablet: maxWidth 300
/// - Mobile: 100% da largura disponível
class EnterpriseSearchField extends StatefulWidget {
  const EnterpriseSearchField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.onChanged,
    this.focusNode,
  });

  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  @override
  State<EnterpriseSearchField> createState() => _EnterpriseSearchFieldState();
}

class _EnterpriseSearchFieldState extends State<EnterpriseSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EnterpriseSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
  }

  double _maxWidthFor(BuildContext context) {
    if (PharmaScreenLayout.isMobile(context)) return double.infinity;
    if (PharmaScreenLayout.isDesktop(context)) return 320;
    return 300; // tablet
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final theme = Theme.of(context);

    final field = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      style: theme.textTheme.erpBody.copyWith(color: t.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: t.textMuted,
          size: t.iconSm,
        ),
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                tooltip: 'Limpar',
                icon: Icon(
                  Icons.clear_rounded,
                  color: t.textMuted,
                  size: t.iconSm,
                ),
                onPressed: _clear,
              )
            : null,
      ),
    );

    final maxWidth = _maxWidthFor(context);
    if (maxWidth == double.infinity) return field;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: field,
    );
  }
}

