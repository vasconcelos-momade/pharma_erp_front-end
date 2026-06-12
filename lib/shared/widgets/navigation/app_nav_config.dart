import 'package:flutter/material.dart';

import '../../../app/router/routes.dart';

/// Itens do menu principal — desktop / drawer (SAP / Odoo style).
class AppNavItem {
  const AppNavItem({
    this.section,
    required this.label,
    required this.path,
    required this.icon,
  });

  final String? section;
  final String label;
  final String path;
  final IconData icon;
}

const List<AppNavItem> kAppNavItems = <AppNavItem>[
  AppNavItem(section: 'Painéis', label: 'Executivo', path: AppRoutePaths.dashboard, icon: Icons.dashboard_outlined),
  AppNavItem(label: 'Farmácia', path: AppRoutePaths.dashboardPharmacy, icon: Icons.local_pharmacy_outlined),
  AppNavItem(label: 'Financeiro', path: AppRoutePaths.dashboardFinance, icon: Icons.account_balance_outlined),
  AppNavItem(label: 'Stock', path: AppRoutePaths.dashboardStock, icon: Icons.warehouse_outlined),
  AppNavItem(section: 'Terminal', label: 'PDV / Caixa', path: AppRoutePaths.pos, icon: Icons.point_of_sale_outlined),
  AppNavItem(section: 'Farmácia & catálogo', label: 'Produtos', path: AppRoutePaths.inventory, icon: Icons.inventory_2_outlined),
  AppNavItem(label: 'Categorias', path: AppRoutePaths.pharmacyCategories, icon: Icons.category_outlined),
  AppNavItem(label: 'Lotes', path: AppRoutePaths.pharmacyLots, icon: Icons.layers_outlined),
  AppNavItem(label: 'Validades', path: AppRoutePaths.pharmacyExpiry, icon: Icons.event_note_outlined),
  AppNavItem(label: 'FEFO', path: AppRoutePaths.pharmacyFefo, icon: Icons.account_tree_outlined),
  AppNavItem(section: 'Regulatório', label: 'Sanitário / alertas', path: AppRoutePaths.regulatory, icon: Icons.health_and_safety_outlined),
  AppNavItem(label: 'Psicotrópicos', path: AppRoutePaths.psychotropics, icon: Icons.medical_information_outlined),
  AppNavItem(label: 'Prescrições', path: AppRoutePaths.recipes, icon: Icons.menu_book_outlined),
  AppNavItem(section: 'Vendas', label: 'Clientes', path: AppRoutePaths.salesCustomers, icon: Icons.people_outline),
  AppNavItem(label: 'Faturas', path: AppRoutePaths.salesInvoices, icon: Icons.receipt_long_outlined),
  AppNavItem(label: 'Histórico vendas', path: AppRoutePaths.salesHistory, icon: Icons.history),
  AppNavItem(section: 'Stock & logística', label: 'Movimentos', path: AppRoutePaths.stockMovements, icon: Icons.swap_horiz),
  AppNavItem(label: 'Requisições', path: AppRoutePaths.stockRequisitions, icon: Icons.assignment_outlined),
  AppNavItem(label: 'Inventário', path: AppRoutePaths.stockInventory, icon: Icons.fact_check_outlined),
  AppNavItem(section: 'Finanças', label: 'Visão geral', path: AppRoutePaths.financial, icon: Icons.payments_outlined),
  AppNavItem(label: 'Fluxo de caixa', path: AppRoutePaths.financeCashflow, icon: Icons.stacked_line_chart),
  AppNavItem(label: 'Despesas', path: AppRoutePaths.financeExpenses, icon: Icons.money_off_csred_outlined),
  AppNavItem(section: 'Auditoria', label: 'Visão geral', path: AppRoutePaths.audit, icon: Icons.gavel_outlined),
  AppNavItem(label: 'Cronologia', path: AppRoutePaths.auditTimeline, icon: Icons.timeline),
  AppNavItem(label: 'Logs', path: AppRoutePaths.auditLogs, icon: Icons.terminal),
  AppNavItem(label: 'Psicotrópicos', path: AppRoutePaths.auditPsych, icon: Icons.verified_user_outlined),
  AppNavItem(section: 'Relatórios', label: 'Relatórios', path: AppRoutePaths.reports, icon: Icons.analytics_outlined),
  AppNavItem(section: 'Administração', label: 'Utilizadores', path: AppRoutePaths.users, icon: Icons.group_outlined),
  AppNavItem(label: 'Perfis', path: AppRoutePaths.userProfiles, icon: Icons.badge_outlined),
  AppNavItem(label: 'Permissões', path: AppRoutePaths.userPermissions, icon: Icons.lock_outline),
  AppNavItem(section: 'Sistema', label: 'Definições', path: AppRoutePaths.settings, icon: Icons.settings_outlined),
  AppNavItem(label: 'Impressoras', path: AppRoutePaths.settingsPrinters, icon: Icons.print_outlined),
  AppNavItem(label: 'Terminais', path: AppRoutePaths.settingsTerminals, icon: Icons.devices_other_outlined),
  AppNavItem(label: 'Sincronização', path: AppRoutePaths.settingsSync, icon: Icons.sync_alt),
];
