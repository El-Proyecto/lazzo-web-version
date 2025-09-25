import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test wrapper that provides the essential providers and theme for widget tests
///
/// Usage:
/// ```dart
/// testWidgets('My widget test', (tester) async {
///   await tester.pumpWidget(TestAppWrapper(
///     child: MyWidget(),
///   ));
/// });
/// ```
class TestAppWrapper extends StatelessWidget {
  const TestAppWrapper({
    super.key,
    required this.child,
    this.overrides = const [],
  });

  final Widget child;
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
        // Use the same theme as the real app
        theme: ThemeData(
          brightness: Brightness.dark,
          // Add other theme properties as needed
        ),
      ),
    );
  }
}

/// Test wrapper for testing widgets that need navigation context
///
/// Usage:
/// ```dart
/// testWidgets('Navigation test', (tester) async {
///   await tester.pumpWidget(TestAppWrapperWithRouter(
///     initialRoute: '/home',
///     child: MyPageWidget(),
///   ));
/// });
/// ```
class TestAppWrapperWithRouter extends StatelessWidget {
  const TestAppWrapperWithRouter({
    super.key,
    required this.child,
    this.overrides = const [],
    this.initialRoute = '/',
  });

  final Widget child;
  final List<Override> overrides;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        initialRoute: initialRoute,
        routes: {
          '/': (context) => child,
          '/home': (context) => child,
          '/auth': (context) => child,
          // Add more routes as needed for testing
        },
        theme: ThemeData(
          brightness: Brightness.dark,
          // Add other theme properties as needed
        ),
      ),
    );
  }
}

/// Helper function to pump a widget with the test wrapper
/// Reduces boilerplate in tests
///
/// Usage:
/// ```dart
/// testWidgets('My test', (tester) async {
///   await pumpTestWidget(tester, MyWidget());
///   // Your test assertions...
/// });
/// ```
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(TestAppWrapper(overrides: overrides, child: widget));
}

/// Helper function to pump a widget with router
///
/// Usage:
/// ```dart
/// testWidgets('My navigation test', (tester) async {
///   await pumpTestWidgetWithRouter(tester, MyPageWidget(), initialRoute: '/home');
///   // Your test assertions...
/// });
/// ```
Future<void> pumpTestWidgetWithRouter(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
  String initialRoute = '/',
}) async {
  await tester.pumpWidget(
    TestAppWrapperWithRouter(
      overrides: overrides,
      initialRoute: initialRoute,
      child: widget,
    ),
  );
}
