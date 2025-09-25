import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Golden test helper utilities for consistent visual regression testing
///
/// Usage requires running: `flutter test --update-goldens` to update golden files
/// Run `flutter test` to compare against existing golden files

/// Standard screen sizes for golden tests
class TestScreenSizes {
  static const Size phone = Size(375, 667);
  static const Size tablet = Size(768, 1024);
  static const Size desktop = Size(1440, 900);
}

/// Simple golden test helper that uses standard Flutter testing
///
/// Usage:
/// ```dart
/// testWidgets('Component golden test', (tester) async {
///   await pumpGoldenWidget(
///     tester,
///     MyComponent(),
///     overrides: [myProviderOverride],
///   );
///   await expectLater(find.byType(MyComponent), matchesGoldenFile('my_component.png'));
/// });
/// ```
Future<void> pumpGoldenWidget(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
  Size screenSize = TestScreenSizes.phone,
}) async {
  // Set the screen size for consistent golden files
  await tester.binding.setSurfaceSize(screenSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          // Match your app's theme
        ),
        home: Scaffold(body: widget),
      ),
    ),
  );

  // Let animations settle
  await tester.pumpAndSettle();
}

/// Helper for testing widget states with golden files
///
/// Usage:
/// ```dart
/// testWidgets('Button states golden', (tester) async {
///   await testWidgetStatesGolden(
///     tester,
///     {
///       'default': MyButton(),
///       'loading': MyButton(isLoading: true),
///       'disabled': MyButton(enabled: false),
///     },
///     'button_states',
///   );
/// });
/// ```
Future<void> testWidgetStatesGolden(
  WidgetTester tester,
  Map<String, Widget> states,
  String baseFileName, {
  List<Override> overrides = const [],
  Size screenSize = TestScreenSizes.phone,
}) async {
  for (final entry in states.entries) {
    final stateName = entry.key;
    final widget = entry.value;

    await pumpGoldenWidget(
      tester,
      widget,
      overrides: overrides,
      screenSize: screenSize,
    );

    await expectLater(
      find.byWidget(widget),
      matchesGoldenFile('${baseFileName}_$stateName.png'),
    );
  }
}

/// Instructions for setting up golden tests:
/// 
/// 1. Create a golden file:
///    - Write a test using `pumpGoldenWidget` and `matchesGoldenFile`
///    - Run `flutter test --update-goldens` to generate the golden file
/// 
/// 2. Verify golden files:
///    - Run `flutter test` to compare against existing golden files
///    - Any pixel differences will cause the test to fail
/// 
/// 3. Update golden files:
///    - After intentional UI changes, run `flutter test --update-goldens`
///    - Review the changes in version control before committing
/// 
/// Example test structure:
/// ```dart
/// import 'package:flutter_test/flutter_test.dart';
/// import '../helpers/golden_test_helper.dart';
/// 
/// void main() {
///   group('Component Golden Tests', () {
///     testWidgets('renders correctly', (tester) async {
///       await pumpGoldenWidget(tester, MyComponent());
///       await expectLater(
///         find.byType(MyComponent), 
///         matchesGoldenFile('my_component.png')
///       );
///     });
///   });
/// }
/// ```