import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// Moldura comum para páginas de módulo (título + conteúdo scrollável).
class ModulePageFrame extends StatelessWidget {
  const ModulePageFrame({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: t.textPrimary,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ],
    );
  }
}
