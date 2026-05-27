/// Caminhos GoRouter (paths) e metadados de navegação.
abstract final class AppRoutePaths {
  AppRoutePaths._();

  static const String login = '/login';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authTenant = '/auth/tenant';

  static const String dashboard = '/dashboard';
  static const String dashboardPharmacy = '/dashboard/pharmacy';
  static const String dashboardFinance = '/dashboard/finance';
  static const String dashboardStock = '/dashboard/stock';

  static const String pos = '/pos';

  static const String inventory = '/inventory';
  static const String pharmacyCategories = '/pharmacy/categories';
  static const String pharmacyLots = '/pharmacy/lots';
  static const String pharmacyExpiry = '/pharmacy/expiry';
  static const String pharmacyFefo = '/pharmacy/fefo';

  static const String regulatory = '/regulatory';
  static const String psychotropics = '/psychotropics';
  static const String recipes = '/recipes';

  static const String financial = '/financial';
  static const String financeCashflow = '/finance/cashflow';
  static const String financeExpenses = '/finance/expenses';

  static const String audit = '/audit';
  static const String auditTimeline = '/audit/timeline';
  static const String auditLogs = '/audit/logs';
  static const String auditPsych = '/audit/psychotropics';

  static const String purchasing = '/purchasing';
  static const String reports = '/reports';

  static const String stockMovements = '/stock/movements';
  static const String stockTransfers = '/stock/transfers';
  static const String stockAdjustments = '/stock/adjustments';
  static const String stockInventory = '/stock/inventory';

  static const String salesCustomers = '/sales/customers';
  static const String salesInvoices = '/sales/invoices';
  static const String salesHistory = '/sales/history';

  static const String users = '/users';
  static const String userProfiles = '/users/profiles';
  static const String userPermissions = '/users/permissions';

  static const String settings = '/settings';
  static const String settingsPrinters = '/settings/printers';
  static const String settingsTerminals = '/settings/terminals';
  static const String settingsSync = '/settings/sync';
}

/// Títulos humanos para topbar / breadcrumbs.
abstract final class AppRouteTitles {
  AppRouteTitles._();

  static String titleFor(String path) {
    return switch (path) {
      AppRoutePaths.login => 'Autenticação',
      AppRoutePaths.authForgotPassword => 'Recuperar palavra-passe',
      AppRoutePaths.authTenant => 'Selecção de unidade',
      AppRoutePaths.dashboard => 'Painel executivo',
      AppRoutePaths.dashboardPharmacy => 'Painel da farmácia',
      AppRoutePaths.dashboardFinance => 'Painel financeiro',
      AppRoutePaths.dashboardStock => 'Painel de stock',
      AppRoutePaths.pos => 'PDV',
      AppRoutePaths.inventory => 'Produtos',
      AppRoutePaths.pharmacyCategories => 'Categorias',
      AppRoutePaths.pharmacyLots => 'Lotes',
      AppRoutePaths.pharmacyExpiry => 'Validades',
      AppRoutePaths.pharmacyFefo => 'FEFO',
      AppRoutePaths.regulatory => 'Sanitário & alertas',
      AppRoutePaths.psychotropics => 'Psicotrópicos',
      AppRoutePaths.recipes => 'Prescrições',
      AppRoutePaths.financial => 'Financeiro',
      AppRoutePaths.financeCashflow => 'Fluxo de caixa',
      AppRoutePaths.financeExpenses => 'Despesas',
      AppRoutePaths.audit => 'Auditoria',
      AppRoutePaths.auditTimeline => 'Cronologia',
      AppRoutePaths.auditLogs => 'Logs',
      AppRoutePaths.auditPsych => 'Auditoria psicotrópicos',
      AppRoutePaths.purchasing => 'Compras & logística',
      AppRoutePaths.reports => 'Relatórios',
      AppRoutePaths.stockMovements => 'Movimentos',
      AppRoutePaths.stockTransfers => 'Transferências',
      AppRoutePaths.stockAdjustments => 'Ajustes',
      AppRoutePaths.stockInventory => 'Inventário',
      AppRoutePaths.salesCustomers => 'Clientes',
      AppRoutePaths.salesInvoices => 'Faturas',
      AppRoutePaths.salesHistory => 'Histórico de vendas',
      AppRoutePaths.users => 'Utilizadores',
      AppRoutePaths.userProfiles => 'Perfis',
      AppRoutePaths.userPermissions => 'Permissões',
      AppRoutePaths.settings => 'Definições',
      AppRoutePaths.settingsPrinters => 'Impressoras',
      AppRoutePaths.settingsTerminals => 'Terminais',
      AppRoutePaths.settingsSync => 'Sincronização',
      _ => path.replaceAll('/', ' ').trim(),
    };
  }

  static String sectionFor(String path) {
    if (path.startsWith('/dashboard')) return 'Painéis';
    if (path.startsWith('/pharmacy') || path == AppRoutePaths.inventory || path == AppRoutePaths.regulatory || path == AppRoutePaths.psychotropics || path == AppRoutePaths.recipes) {
      return 'Farmácia & regulatório';
    }
    if (path.startsWith('/sales')) return 'Vendas';
    if (path.startsWith('/stock')) return 'Stock';
    if (path.startsWith('/finance') || path == AppRoutePaths.financial) return 'Finanças';
    if (path.startsWith('/audit') || path == AppRoutePaths.audit) return 'Auditoria';
    if (path.startsWith('/users')) return 'Utilizadores';
    if (path.startsWith('/settings')) return 'Sistema';
    if (path.startsWith('/auth')) return 'Conta';
    if (path == AppRoutePaths.pos) return 'Terminal';
    if (path == AppRoutePaths.purchasing || path == AppRoutePaths.reports) return 'Operações';
    return 'Pharma ERP';
  }
}
