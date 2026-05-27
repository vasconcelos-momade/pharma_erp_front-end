import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pharma_erp/app/app.dart';
import 'package:pharma_erp/app/providers/auth_session_notifier.dart';
import 'package:pharma_erp/app/router/go_app_router.dart';
import 'package:pharma_erp/app/router/routes.dart';
import 'package:pharma_erp/modules/auth/domain/entities/auth_session.dart';
import 'package:pharma_erp/modules/auth/domain/entities/auth_user.dart';
import 'package:pharma_erp/modules/auth/domain/entities/branch_access.dart';
import 'package:pharma_erp/modules/auth/domain/entities/tenant_access.dart';

AuthSessionState _authenticatedState() {
  const tenant = TenantAccess(
    id: '1',
    companyName: 'Demo',
    name: 'demo',
    branches: [
      BranchAccess(id: '1', code: 'HQ', name: 'Matriz'),
    ],
  );
  return AuthSessionState(
    session: AuthSession(
      accessToken: 'test-token',
      user: AuthUser(
        id: '1',
        name: 'Test',
        email: 'test@demo.com',
        role: 'admin',
      ),
      tenants: [tenant],
      tenantId: '1',
      branchId: '1',
    ),
  );
}

void main() {
  testWidgets('Login mostra formulário', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PharmaErpApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Pharma ERP'), findsWidgets);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('Navegação para inventário com sessão mock', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(_MockAuthSessionNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PharmaErpApp(),
      ),
    );
    await tester.pumpAndSettle();

    container.read(goRouterProvider).go(AppRoutePaths.inventory);
    await tester.pumpAndSettle();

    expect(find.textContaining('PRODUTOS'), findsWidgets);
  });
}

class _MockAuthSessionNotifier extends AuthSessionNotifier {
  @override
  AuthSessionState build() => _authenticatedState();
}
