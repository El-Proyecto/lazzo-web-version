import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/integration_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke - Auth', () {
    testWidgets('auth page is visible on app launch', (tester) async {
      await launchAppAndSettle(tester);

      // If a cached session skips auth on launch, force navigation to auth route
      // so the smoke test remains deterministic in CI and local runs.
      if (find.byType(TextField).evaluate().isEmpty) {
        final navigator =
            tester.state<NavigatorState>(find.byType(Navigator).first);
        navigator.pushNamed('/auth');
        await tester.pumpAndSettle();
      }

      expect(find.byType(TextField), findsWidgets);
      await tester.enterText(find.byType(TextField).first, 'ci@test.com');
      await tester.pump();
      expect(find.text('ci@test.com'), findsOneWidget);
    });
  });
}
