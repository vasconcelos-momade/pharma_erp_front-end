import 'package:flutter/material.dart';

import '../../../app/providers/session_access_notifier.dart';
import '../../../app/router/routes.dart';

/// Entrada de navegação (item folha).
class AppNavItem {
  const AppNavItem({
    this.section,
    required this.label,
    required this.path,
    required this.icon,
  });

  /// Título do grupo ERP quando este item abre uma secção.
  final String? section;
  final String label;
  final String path;
  final IconData icon;

  bool get isSectionLead => section != null;
}

/// Grupo de navegação (Primavera / SAP B1 / Odoo style).
class AppNavSection {
  const AppNavSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<AppNavItem> items;
}

/// Hierarquia oficial do menu — única fonte para sidebar e drawer.
const List<AppNavSection> kAppNavSections = <AppNavSection>[
  AppNavSection(
    title: 'Dashboard',
    items: <AppNavItem>[
      AppNavItem(
        label: 'Executivo',
        path: AppRoutePaths.dashboard,
        icon: Icons.dashboard_outlined,
      ),
      AppNavItem(
        label: 'Farmácia',
        path: AppRoutePaths.dashboardPharmacy,
        icon: Icons.local_pharmacy_outlined,
      ),
      AppNavItem(
        label: 'Financeiro',
        path: AppRoutePaths.dashboardFinance,
        icon: Icons.account_balance_outlined,
      ),
      AppNavItem(
        label: 'Stock',
        path: AppRoutePaths.dashboardStock,
        icon: Icons.warehouse_outlined,
      ),
    ],
  ),
  AppNavSection(
    title: 'Terminal',
    items: <AppNavItem>[
      AppNavItem(
        label: 'POS / Caixa',
        path: AppRoutePaths.pos,
        icon: Icons.point_of_sale_outlined,
      ),
      AppNavItem(
        label: 'Faturas',
        path: AppRoutePaths.salesInvoices,
        icon: Icons.receipt_long_outlined,
      ),
      AppNavItem(
        label: 'Cotações',
        path: AppRoutePaths.salesQuotations,
        icon: Icons.request_quote_outlined,
      ),
      AppNavItem(
        label: 'Clientes',
        path: AppRoutePaths.salesCustomers,
        icon: Icons.people_outline,
      ),
      AppNavItem(
        label: 'Histórico de Vendas',
        path: AppRoutePaths.salesHistory,
        icon: Icons.history,
      ),
    ],
  ),
  AppNavSection(
    title: 'Farmácia',
    items: <AppNavItem>[
      AppNavItem(
        label: 'Produtos',
        path: AppRoutePaths.products,
        icon: Icons.inventory_2_outlined,
      ),
      AppNavItem(
        label: 'Categorias',
        path: AppRoutePaths.pharmacyCategories,
        icon: Icons.category_outlined,
      ),
      AppNavItem(
        label: 'Lotes',
        path: AppRoutePaths.pharmacyLots,
        icon: Icons.layers_outlined,
      ),
      AppNavItem(
        label: 'Validades',
        path: AppRoutePaths.pharmacyExpiry,
        icon: Icons.event_note_outlined,
      ),
      AppNavItem(
        label: 'FEFO',
        path: AppRoutePaths.pharmacyFefo,
        icon: Icons.account_tree_outlined,
      ),
    ],
  ),
  AppNavSection(
    title: 'Stock & Logística',
    items: <AppNavItem>[
      AppNavItem(
        label: 'Inventário',
        path: AppRoutePaths.stockInventory,
        icon: Icons.fact_check_outlined,
      ),
      AppNavItem(
        label: 'Movimentos',
        path: AppRoutePaths.stockMovements,
        icon: Icons.swap_horiz,
      ),
      AppNavItem(
        label: 'Requisições',
        path: AppRoutePaths.stockRequisitions,
        icon: Icons.assignment_outlined,
      ),
    ],
  ),
  AppNavSection(
    title: 'Financeiro',
    items: <AppNavItem>[
      AppNavItem(
        label: 'Visão Geral',
        path: AppRoutePaths.financial,
        icon: Icons.payments_outlined,
      ),
      AppNavItem(
        label: 'Fluxo de Caixa',
        path: AppRoutePaths.financeCashflow,
        icon: Icons.stacked_line_chart,
      ),
      AppNavItem(
        label: 'Despesas',
        path: AppRoutePaths.financeExpenses,
        icon: Icons.money_off_csred_outlined,
      ),
    ],
  ),
  AppNavSection(
    title: 'Regulatório',
    items: <AppNavItem>[
      AppNavItem(
        label: 'Receitas',
        path: AppRoutePaths.recipes,
        icon: Icons.description_outlined,
      ),
      AppNavItem(
        label: 'Livro de Receitas',
        path: AppRoutePaths.recipesBook,
        icon: Icons.menu_book_outlined,
      ),
      AppNavItem(
        label: 'Livro de Psicotrópicos',
        path: AppRoutePaths.psychotropics,
        icon: Icons.medical_information_outlined,
      ),
      AppNavItem(
        label: 'Sanitário / Alertas',
        path: AppRoutePaths.regulatory,
        icon: Icons.health_and_safety_outlined,
      ),
    ],
  ),
  AppNavSection(
    title: 'Auditoria',
    items: <AppNavItem>[
      AppNavItem(
        label: 'Visão Geral',
        path: AppRoutePaths.audit,
        icon: Icons.gavel_outlined,
      ),
      AppNavItem(
        label: 'Cronologia',
        path: AppRoutePaths.auditTimeline,
        icon: Icons.timeline,
      ),
      AppNavItem(
        label: 'Logs',
        path: AppRoutePaths.auditLogs,
        icon: Icons.terminal,
      ),
      AppNavItem(
        label: 'Auditoria de Psicotrópicos',
        path: AppRoutePaths.auditPsych,
        icon: Icons.verified_user_outlined,
      ),
    ],
  ),
  AppNavSection(
    title: 'Administração',
    items: <AppNavItem>[
      AppNavItem(
        label: 'Utilizadores',
        path: AppRoutePaths.users,
        icon: Icons.group_outlined,
      ),
    ],
  ),
  AppNavSection(
    title: 'Sistema',
    items: <AppNavItem>[
      AppNavItem(
        label: 'Definições',
        path: AppRoutePaths.settings,
        icon: Icons.settings_outlined,
      ),
      AppNavItem(
        label: 'Impressoras',
        path: AppRoutePaths.settingsPrinters,
        icon: Icons.print_outlined,
      ),
      AppNavItem(
        label: 'Terminais',
        path: AppRoutePaths.settingsTerminals,
        icon: Icons.devices_other_outlined,
      ),
      AppNavItem(
        label: 'Sincronização',
        path: AppRoutePaths.settingsSync,
        icon: Icons.sync_alt,
      ),
    ],
  ),
];

/// Lista plana com metadado [AppNavItem.section] no primeiro item de cada grupo.
List<AppNavItem> buildFlatNavItems(List<AppNavSection> sections) {
  final flat = <AppNavItem>[];
  for (final group in sections) {
    for (var index = 0; index < group.items.length; index++) {
      final item = group.items[index];
      flat.add(
        AppNavItem(
          section: index == 0 ? group.title : null,
          label: item.label,
          path: item.path,
          icon: item.icon,
        ),
      );
    }
  }
  return flat;
}

/// Itens do menu principal — desktop / drawer (ERP).
final List<AppNavItem> kAppNavItems = buildFlatNavItems(kAppNavSections);

List<AppNavItem> visibleNavItemsForAccess(SessionAccessState access) {
  if (access.canAccessAdministration) {
    return kAppNavItems;
  }
  return kAppNavItems
      .where((item) => item.path != AppRoutePaths.users)
      .toList(growable: false);
}

/// Resolve o grupo ERP de um path (breadcrumbs / topbar).
String? navSectionTitleForPath(String path) {
  for (final group in kAppNavSections) {
    if (group.items.any((item) => item.path == path)) {
      return group.title;
    }
  }
  return AppRouteTitles.sectionFor(path);
}
