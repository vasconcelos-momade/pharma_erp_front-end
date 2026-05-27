import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/layout/module_page_frame.dart';

class PurchasingHubPage extends StatelessWidget {
  const PurchasingHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return ModulePageFrame(
      title: 'COMPRAS & LOGÍSTICA',
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.local_shipping_outlined, color: t.brandGreen),
            title: Text('Encomenda #PO-2026-014', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700)),
            subtitle: Text('Fornecedor MedMoz • ETA 3 dias', style: TextStyle(color: t.textMuted)),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.inventory_2_outlined, color: t.posInfo),
            title: Text('Receção parcial', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700)),
            subtitle: Text('Conferência documental', style: TextStyle(color: t.textMuted)),
          ),
        ],
      ),
    );
  }
}
