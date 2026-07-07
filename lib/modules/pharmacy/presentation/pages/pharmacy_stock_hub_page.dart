import 'package:flutter/material.dart';

import '../../../../shared/widgets/layout/enterprise_tab_hub.dart';
import '../../expiry/presentation/pages/expiry_page.dart';
import '../../fefo/presentation/pages/fefo_page.dart';
import '../../lots/presentation/pages/lots_page.dart';

enum PharmacyStockHubTab { lots, expiry, fefo }

/// Stock farmacêutico unificado — lotes, validades e FEFO em tabs.
class PharmacyStockHubPage extends StatelessWidget {
  const PharmacyStockHubPage({super.key, this.initialTab = 0});

  final int initialTab;

  static int indexFor(PharmacyStockHubTab tab) => switch (tab) {
        PharmacyStockHubTab.lots => 0,
        PharmacyStockHubTab.expiry => 1,
        PharmacyStockHubTab.fefo => 2,
      };

  @override
  Widget build(BuildContext context) {
    return EnterpriseTabHub(
      compact: true,
      initialIndex: initialTab,
      tabs: const [
        EnterpriseTabHubTab(
          label: 'Lotes',
          icon: Icons.layers_outlined,
          body: LotsPage(),
        ),
        EnterpriseTabHubTab(
          label: 'Validades',
          icon: Icons.event_note_outlined,
          body: ExpiryPage(),
        ),
        EnterpriseTabHubTab(
          label: 'FEFO',
          icon: Icons.account_tree_outlined,
          body: FefoPage(),
        ),
      ],
    );
  }
}
