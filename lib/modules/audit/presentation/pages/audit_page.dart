import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/layout/module_page_frame.dart';

class AuditPage extends StatelessWidget {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return ModulePageFrame(
      title: 'AUDITORIA',
      child: Column(
        children: [
          for (var i = 0; i < 8; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: t.card,
                borderRadius: BorderRadius.circular(t.radiusMd),
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.history, color: t.textSecondary, size: 20),
                  title: Text('login • utilizador #${10 + i}', style: TextStyle(color: t.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('${DateTime.now().subtract(Duration(minutes: i * 3))}', style: TextStyle(color: t.textMuted, fontSize: 11)),
                  trailing: Chip(label: const Text('OK'), backgroundColor: t.brandGreen.withValues(alpha: 0.12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
