import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../modules/admin/users/presentation/pages/users_page.dart';
import '../../modules/audit/presentation/pages/audit_logs_page.dart';
import '../../modules/audit/presentation/pages/audit_page.dart';
import '../../modules/audit/presentation/pages/audit_timeline_page.dart';
import '../../modules/sales/customers/presentation/pages/customers_page.dart';
import '../../modules/sales/history/presentation/pages/sales_history_page.dart';
import '../../modules/auth/presentation/pages/forgot_password_page.dart';
import '../../modules/auth/presentation/pages/login_page.dart';
import '../../modules/auth/presentation/pages/tenant_select_page.dart';
import '../../modules/dashboard/presentation/pages/executive_dashboard_page.dart';
import '../../modules/dashboard/presentation/pages/finance_dashboard_page.dart';
import '../../modules/dashboard/presentation/pages/pharmacy_dashboard_page.dart';
import '../../modules/dashboard/presentation/pages/stock_dashboard_page.dart';
import '../../modules/finance/presentation/pages/financial_page.dart';
import '../../modules/pharmacy/prescriptions/presentation/pages/recipes_book_page.dart';
import '../../modules/pharmacy/products/presentation/pages/products_page.dart';
import '../../modules/pharmacy/categories/presentation/pages/categories_page.dart';
import '../../modules/pharmacy/lots/presentation/pages/lots_page.dart';
import '../../modules/pharmacy/expiry/presentation/pages/expiry_page.dart';
import '../../modules/pharmacy/fefo/presentation/pages/fefo_page.dart';
import '../../modules/pharmacy/psychotropics/presentation/pages/psychotropics_book_page.dart';
import '../../modules/pharmacy/sanitary/presentation/pages/regulatory_page.dart';
import '../../modules/sales/quotations/presentation/pages/quotations_page.dart';
import '../../modules/sales/invoices/presentation/pages/invoices_page.dart';
import '../../modules/sales/pdv/presentation/pages/pdv_page.dart';
import '../../modules/stock/presentation/pages/inventory_hub_page.dart';
import '../../modules/stock/presentation/pages/movimentacoes_hub_page.dart';
import '../../modules/stock/presentation/pages/requisicao_hub_page.dart';
import '../../shared/layouts/app_main_shell.dart';
import '../../shared/layouts/pos_shell_layout.dart';
import '../../shared/presentation/stub_pages.dart'
    hide
        AuditLogsPage,
        AuditTimelinePage,
        CustomersPage,
        SalesHistoryPage,
        UsersPage;
import '../app_observer.dart';
import '../providers/auth_session_notifier.dart';
import '../providers/session_access_notifier.dart';
import 'router_refresh.dart';
import 'routes.dart';

bool _isPublicAuthRoute(String loc) {
  return loc == AppRoutePaths.login || loc == AppRoutePaths.authForgotPassword;
}

bool _isAdministrationRoute(String loc) {
  return loc == AppRoutePaths.users;
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: AppRoutePaths.login,
    refreshListenable: refresh,
    observers: [AppNavigatorObserver()],
    redirect: (context, state) {
      final auth = ref.read(authSessionProvider);
      final access = ref.read(sessionAccessProvider);
      final loc = state.matchedLocation;

      if (auth.isBootstrapping) {
        return null;
      }

      if (!auth.isAuthenticated) {
        if (_isPublicAuthRoute(loc)) return null;
        return AppRoutePaths.login;
      }

      if (!auth.hasTenantContext) {
        if (loc == AppRoutePaths.authTenant) return null;
        if (_isPublicAuthRoute(loc)) return AppRoutePaths.authTenant;
        return AppRoutePaths.authTenant;
      }

      if (loc == AppRoutePaths.login ||
          loc == AppRoutePaths.authForgotPassword ||
          loc == AppRoutePaths.authTenant) {
        return AppRoutePaths.dashboard;
      }

      if (_isAdministrationRoute(loc) && !access.isResolved) {
        return null;
      }

      if (_isAdministrationRoute(loc) && !access.canAccessAdministration) {
        return AppRoutePaths.dashboard;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutePaths.authForgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutePaths.authTenant,
        name: 'tenant',
        builder: (context, state) => const TenantSelectPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppMainShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutePaths.dashboard,
            name: 'dashboard',
            builder: (context, state) => const ExecutiveDashboardPage(),
          ),
          GoRoute(
            path: AppRoutePaths.dashboardPharmacy,
            name: 'dashboard-pharmacy',
            builder: (context, state) => const PharmacyDashboardPage(),
          ),
          GoRoute(
            path: AppRoutePaths.dashboardFinance,
            name: 'dashboard-finance',
            builder: (context, state) => const FinanceDashboardPage(),
          ),
          GoRoute(
            path: AppRoutePaths.dashboardStock,
            name: 'dashboard-stock',
            builder: (context, state) => const StockDashboardPage(),
          ),
          GoRoute(
            path: AppRoutePaths.products,
            name: 'products',
            builder: (context, state) => const ProductsPage(),
          ),
          GoRoute(
            path: AppRoutePaths.pharmacyCategories,
            name: 'pharmacy-categories',
            builder: (context, state) => const CategoriesPage(),
          ),
          GoRoute(
            path: AppRoutePaths.pharmacyLots,
            name: 'pharmacy-lots',
            builder: (context, state) => const LotsPage(),
          ),
          GoRoute(
            path: AppRoutePaths.pharmacyExpiry,
            name: 'pharmacy-expiry',
            builder: (context, state) => const ExpiryPage(),
          ),
          GoRoute(
            path: AppRoutePaths.pharmacyFefo,
            name: 'pharmacy-fefo',
            builder: (context, state) => const FefoPage(),
          ),
          GoRoute(
            path: AppRoutePaths.regulatory,
            name: 'regulatory',
            builder: (context, state) => const RegulatoryPage(),
          ),
          GoRoute(
            path: AppRoutePaths.psychotropics,
            name: 'psychotropics',
            builder: (context, state) => const PsychotropicsBookPage(),
          ),
          GoRoute(
            path: AppRoutePaths.recipes,
            name: 'recipes',
            builder: (context, state) => const RecipesBookPage(),
          ),
          GoRoute(
            path: AppRoutePaths.recipesBook,
            name: 'recipes-book',
            builder: (context, state) =>
                const RecipesBookPage(initialTab: RecipesBookTab.book),
          ),
          GoRoute(
            path: AppRoutePaths.financial,
            name: 'financial',
            builder: (context, state) => const FinancialPage(),
          ),
          GoRoute(
            path: AppRoutePaths.financeCashflow,
            name: 'finance-cashflow',
            builder: (context, state) => const CashflowPage(),
          ),
          GoRoute(
            path: AppRoutePaths.financeExpenses,
            name: 'finance-expenses',
            builder: (context, state) => const ExpensesPage(),
          ),
          GoRoute(
            path: AppRoutePaths.audit,
            name: 'audit',
            builder: (context, state) => const AuditPage(),
          ),
          GoRoute(
            path: AppRoutePaths.auditTimeline,
            name: 'audit-timeline',
            builder: (context, state) => const AuditTimelinePage(),
          ),
          GoRoute(
            path: AppRoutePaths.auditLogs,
            name: 'audit-logs',
            builder: (context, state) => const AuditLogsPage(),
          ),
          GoRoute(
            path: AppRoutePaths.auditPsych,
            name: 'audit-psych',
            builder: (context, state) => const AuditPsychPage(),
          ),
          GoRoute(
            path: AppRoutePaths.purchasing,
            redirect: (context, state) => AppRoutePaths.stockRequisitions,
          ),
          GoRoute(
            path: AppRoutePaths.comprasLegacy,
            redirect: (context, state) => AppRoutePaths.stockRequisitions,
          ),
          GoRoute(
            path: AppRoutePaths.reports,
            redirect: (context, state) => AppRoutePaths.dashboard,
          ),
          GoRoute(
            path: AppRoutePaths.stockMovements,
            name: 'stock-movements',
            builder: (context, state) => const MovimentacoesHubPage(),
          ),
          GoRoute(
            path: AppRoutePaths.stockRequisitions,
            name: 'stock-requests',
            builder: (context, state) => const RequisicaoHubPage(),
          ),
          GoRoute(
            path: AppRoutePaths.stockRequisitionsLegacy,
            redirect: (context, state) => AppRoutePaths.stockRequisitions,
          ),
          GoRoute(
            path: AppRoutePaths.stockTransfersLegacy,
            redirect: (context, state) => AppRoutePaths.stockRequisitions,
          ),

          GoRoute(
            path: AppRoutePaths.stockInventory,
            name: 'stock-inventory',
            builder: (context, state) => const InventoryHubPage(),
          ),
          GoRoute(
            path: AppRoutePaths.salesCustomers,
            name: 'sales-customers',
            builder: (context, state) => const CustomersPage(),
          ),
          GoRoute(
            path: AppRoutePaths.salesInvoices,
            name: 'sales-invoices',
            builder: (context, state) => const SalesInvoicesPage(),
          ),
          GoRoute(
            path: AppRoutePaths.salesQuotations,
            name: 'sales-quotations',
            builder: (context, state) => const SalesQuotationsPage(),
          ),
          GoRoute(
            path: AppRoutePaths.salesHistory,
            name: 'sales-history',
            builder: (context, state) => const SalesHistoryPage(),
          ),
          GoRoute(
            path: AppRoutePaths.users,
            name: 'users',
            builder: (context, state) => const UsersPage(),
          ),
          GoRoute(
            path: AppRoutePaths.userProfiles,
            redirect: (context, state) => AppRoutePaths.users,
          ),
          GoRoute(
            path: AppRoutePaths.userPermissions,
            redirect: (context, state) => AppRoutePaths.users,
          ),
          GoRoute(
            path: AppRoutePaths.settings,
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: AppRoutePaths.settingsPrinters,
            name: 'settings-printers',
            builder: (context, state) => const PrintersPage(),
          ),
          GoRoute(
            path: AppRoutePaths.settingsTerminals,
            name: 'settings-terminals',
            builder: (context, state) => const TerminalsPage(),
          ),
          GoRoute(
            path: AppRoutePaths.settingsSync,
            name: 'settings-sync',
            builder: (context, state) => const SyncSettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutePaths.pos,
        name: 'pos',
        builder: (context, state) => const PosShellLayout(child: PdvPage()),
      ),
    ],
  );
});
