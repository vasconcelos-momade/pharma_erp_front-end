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

  static const String products = '/products';
  static const String pharmacyCategories = '/pharmacy/categories';
  static const String pharmacyLots = '/pharmacy/lots';
  static const String pharmacyExpiry = '/pharmacy/expiry';
  static const String pharmacyFefo = '/pharmacy/fefo';

  static const String regulatory = '/regulatory';
  static const String psychotropics = '/psychotropics';
  static const String recipes = '/recipes';
  static const String recipesBook = '/recipes/book';

  static const String financial = '/financial';
  static const String financeCashflow = '/finance/cashflow';
  static const String financeExpenses = '/finance/expenses';

  static const String audit = '/audit';
  static const String auditTimeline = '/audit/timeline';
  static const String auditLogs = '/audit/logs';
  static const String auditPsych = '/audit/psychotropics';

  /// Rota legada de compras — redireccionada para [stockRequisitions].
  static const String purchasing = '/purchasing';

  /// Alias legado `/compras` — redireccionado para [stockRequisitions].
  static const String comprasLegacy = '/compras';
  static const String reports = '/reports';

  static const String stockMovements = '/stock/movements';
  static const String stockRequisitions = '/stock/requests';

  /// Rota legada PT — redireccionada para [stockRequisitions].
  static const String stockRequisitionsLegacy = '/stock/requisicoes';

  /// Rota legada — redireccionada para [stockRequisitions].
  static const String stockTransfersLegacy = '/stock/transferencias';
  static const String stockInventory = '/stock/inventory';

  static const String salesCustomers = '/sales/customers';
  static const String salesInvoices = '/sales/invoices';
  static const String salesQuotations = '/sales/quotations';
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
      AppRoutePaths.dashboard => 'Executivo',
      AppRoutePaths.dashboardPharmacy => 'Farmácia',
      AppRoutePaths.dashboardFinance => 'Financeiro',
      AppRoutePaths.dashboardStock => 'Stock',
      AppRoutePaths.pos => 'POS / Caixa',
      AppRoutePaths.products => 'Produtos',
      AppRoutePaths.pharmacyCategories => 'Categorias',
      AppRoutePaths.pharmacyLots => 'Lotes',
      AppRoutePaths.pharmacyExpiry => 'Validades',
      AppRoutePaths.pharmacyFefo => 'FEFO',
      AppRoutePaths.regulatory => 'Sanitário / Alertas',
      AppRoutePaths.psychotropics => 'Livro de Psicotrópicos',
      AppRoutePaths.recipes => 'Receitas',
      AppRoutePaths.recipesBook => 'Livro de Receitas',
      AppRoutePaths.financial => 'Visão Geral',
      AppRoutePaths.financeCashflow => 'Fluxo de Caixa',
      AppRoutePaths.financeExpenses => 'Despesas',
      AppRoutePaths.audit => 'Visão Geral',
      AppRoutePaths.auditTimeline => 'Cronologia',
      AppRoutePaths.auditLogs => 'Logs',
      AppRoutePaths.auditPsych => 'Auditoria de Psicotrópicos',
      AppRoutePaths.purchasing => 'Requisições',
      AppRoutePaths.comprasLegacy => 'Requisições',
      AppRoutePaths.reports => 'Relatórios',
      AppRoutePaths.stockMovements => 'Movimentos',
      AppRoutePaths.stockRequisitions => 'Requisições',
      AppRoutePaths.stockRequisitionsLegacy => 'Requisições',
      AppRoutePaths.stockTransfersLegacy => 'Requisições',
      AppRoutePaths.stockInventory => 'Inventário',
      AppRoutePaths.salesCustomers => 'Clientes',
      AppRoutePaths.salesInvoices => 'Faturas',
      AppRoutePaths.salesQuotations => 'Cotações',
      AppRoutePaths.salesHistory => 'Histórico de Vendas',
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
    if (path.startsWith('/dashboard')) return 'Dashboard';
    if (path.startsWith('/pharmacy') || path == AppRoutePaths.products) {
      return 'Farmácia';
    }
    if (path.startsWith('/sales') || path == AppRoutePaths.pos) {
      return 'Terminal';
    }
    if (path.startsWith('/stock')) return 'Stock & Logística';
    if (path == AppRoutePaths.regulatory ||
        path == AppRoutePaths.psychotropics ||
        path == AppRoutePaths.recipes ||
        path == AppRoutePaths.recipesBook) {
      return 'Regulatório';
    }
    if (path.startsWith('/finance') || path == AppRoutePaths.financial) {
      return 'Financeiro';
    }
    if (path.startsWith('/audit') || path == AppRoutePaths.audit) {
      return 'Auditoria';
    }
    if (path.startsWith('/users')) {
      return 'Administração';
    }
    if (path.startsWith('/settings')) {
      return 'Sistema';
    }
    if (path.startsWith('/auth')) {
      return 'Conta';
    }
    if (path == AppRoutePaths.purchasing) {
      return 'Stock & Logística';
    }
    return 'Pharma ERP';
  }
}
