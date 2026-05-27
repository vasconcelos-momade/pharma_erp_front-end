import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pharma_erp/app/app.dart';

void main() {
  testWidgets('App arranca no login', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PharmaErpApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Pharma ERP'), findsWidgets);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
