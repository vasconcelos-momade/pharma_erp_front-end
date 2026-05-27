import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../shared/widgets/layout/module_page_frame.dart';

class RegulatoryPage extends StatelessWidget {
  const RegulatoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return ModulePageFrame(
      title: 'SANITÁRIO / ALERTAS ANARME',
      child: Column(
        children: [
          _AlertTile(t: t, title: 'Validade próxima', subtitle: 'Lote LOT-9982 • Amoxicilina', severity: t.posWarning),
          _AlertTile(t: t, title: 'Divergência inventário', subtitle: 'Terminal #02 vs stock central', severity: t.posDanger),
          _AlertTile(t: t, title: 'Temperatura câmara', subtitle: 'Cadeia fria OK', severity: t.brandGreen),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.t, required this.title, required this.subtitle, required this.severity});
  final PharmaTokens t;
  final String title;
  final String subtitle;
  final Color severity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: ListTile(
          leading: Icon(Icons.shield_outlined, color: severity),
          title: Text(title, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle, style: TextStyle(color: t.textMuted)),
        ),
      ),
    );
  }
}
