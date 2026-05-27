import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../shared/widgets/layout/module_page_frame.dart';

class RecipesBookPage extends StatelessWidget {
  const RecipesBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return ModulePageFrame(
      title: 'LIVRO DE RECEITAS',
      child: Column(
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: t.card,
                borderRadius: BorderRadius.circular(t.radiusMd),
                child: ListTile(
                  leading: Icon(Icons.menu_book_outlined, color: t.posInfo),
                  title: Text('Receita #${2400 + i}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700)),
                  subtitle: Text('Médico • utente • ANARME', style: TextStyle(color: t.textMuted, fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
