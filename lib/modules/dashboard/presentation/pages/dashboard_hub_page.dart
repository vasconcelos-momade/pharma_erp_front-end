import 'package:flutter/material.dart';

import '../../../../shared/widgets/layout/enterprise_tab_hub.dart';
import 'executive_dashboard_page.dart';
import 'finance_dashboard_page.dart';
import 'pharmacy_dashboard_page.dart';
import 'stock_dashboard_page.dart';

/// Painel unificado — substitui 4 rotas de dashboard por tabs.
class DashboardHubPage extends StatelessWidget {
  const DashboardHubPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return EnterpriseTabHub(
      compact: true,
      initialIndex: initialTab,
      tabs: const [
        EnterpriseTabHubTab(
          label: 'Executivo',
          icon: Icons.dashboard_outlined,
          body: ExecutiveDashboardPage(),
        ),
        EnterpriseTabHubTab(
          label: 'Farmácia',
          icon: Icons.local_pharmacy_outlined,
          body: PharmacyDashboardPage(),
        ),
        EnterpriseTabHubTab(
          label: 'Financeiro',
          icon: Icons.account_balance_outlined,
          body: FinanceDashboardPage(),
        ),
        EnterpriseTabHubTab(
          label: 'Stock',
          icon: Icons.warehouse_outlined,
          body: StockDashboardPage(),
        ),
      ],
    );
  }
}
