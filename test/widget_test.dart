import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_providers.dart';

void main() {
  testWidgets('App arranca no login', (WidgetTester tester) async {
    await tester.pumpWidget(testLoginApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Pharma ERP'), findsWidgets);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
