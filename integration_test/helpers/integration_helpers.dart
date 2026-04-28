import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/main.dart' as app;

Future<void> launchAppAndSettle(
  WidgetTester tester, {
  Duration settleDuration = const Duration(seconds: 3),
}) async {
  app.main();
  await tester.pumpAndSettle(settleDuration);
}
