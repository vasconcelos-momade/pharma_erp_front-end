import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// Moldura comum para páginas de módulo (título opcional + conteúdo scrollável).
class ModulePageFrame extends StatelessWidget {
  const ModulePageFrame({
    super.key,
    this.title,
    required this.child,
    this.actions = const <Widget>[],
  });

  final String? title;
  final Widget child;
  final List<Widget> actions;

  bool get _showsHeader =>
      (title != null && title!.trim().isNotEmpty) || actions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showsHeader)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null && title!.trim().isNotEmpty)
                Expanded(
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: t.textPrimary,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (actions.isNotEmpty) ...[
                if (title != null && title!.trim().isNotEmpty)
                  const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                ),
              ],
            ],
          ),
        if (_showsHeader) const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ],
    );
  }
}
