import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/profile/presentation/edit_profile_page.dart';

void main() {
  group('EditProfilePage Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('shows loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(home: EditProfilePage()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('shows profile data when loaded', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(home: EditProfilePage()),
        ),
      );

      // Wait for the async data to load
      await tester.pump();
      await tester.pump(Duration(seconds: 2));

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Birthday'), findsOneWidget);
    });

    testWidgets('shows editable profile photo', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(home: EditProfilePage()),
        ),
      );

      // Wait for the async data to load
      await tester.pump();
      await tester.pump(Duration(seconds: 2));

      // Find the profile photo with camera icon overlay
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('can edit name field', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(home: EditProfilePage()),
        ),
      );

      // Wait for the async data to load
      await tester.pump();
      await tester.pump(Duration(seconds: 2));

      // Find and tap the edit icon for name field
      final editIcons = find.byIcon(Icons.edit_outlined);
      expect(editIcons, findsWidgets);

      await tester.tap(editIcons.first);
      await tester.pump();

      // Should now show Save and Cancel buttons
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('can cancel editing', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(home: EditProfilePage()),
        ),
      );

      // Wait for the async data to load
      await tester.pump();
      await tester.pump(Duration(seconds: 2));

      // Start editing
      final editIcons = find.byIcon(Icons.edit_outlined);
      await tester.tap(editIcons.first);
      await tester.pump();

      // Cancel editing
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      // Should return to view state
      expect(find.text('Save'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('shows tap to add for empty optional fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(home: EditProfilePage()),
        ),
      );

      // Wait for the async data to load
      await tester.pump();
      await tester.pump(Duration(seconds: 2));

      // Optional fields without values should show "Tap to add"
      expect(find.text('Tap to add'), findsWidgets);
    });
  });
}
