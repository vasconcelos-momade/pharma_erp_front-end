import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../shared/widgets/layout/module_page_frame.dart';

class PsychotropicsBookPage extends StatelessWidget {
  const PsychotropicsBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return ModulePageFrame(
      title: 'LIVRO DE PSICOTRÓPICOS',
      child: Column(
        children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: t.card,
                borderRadius: BorderRadius.circular(t.radiusMd),
                child: ListTile(
                  title: Text('MOV ${2026 - i}-PSI', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800)),
                  subtitle: Text('Saída • receita validada', style: TextStyle(color: t.textMuted)),
                  trailing: Icon(Icons.verified, color: t.brandGreen),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
