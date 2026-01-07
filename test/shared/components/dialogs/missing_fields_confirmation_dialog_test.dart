import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/shared/components/dialogs/missing_fields_confirmation_dialog.dart';

void main() {
  group('MissingFieldsConfirmationDialog', () {
    testWidgets('shows correct message when both fields missing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MissingFieldsConfirmationDialog(
            hasLocation: false,
            hasDate: false,
          ),
        ),
      );

      expect(find.text('Cannot Confirm Event'), findsOneWidget);
      expect(
        find.text(
            'You need to define both date and location before confirming this event.'),
        findsOneWidget,
      );
      expect(find.text('Ok'), findsOneWidget);
    });

    testWidgets('shows correct message when only location missing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MissingFieldsConfirmationDialog(
            hasLocation: false,
            hasDate: true,
          ),
        ),
      );

      expect(find.text('Cannot Confirm Event'), findsOneWidget);
      expect(
        find.text(
            'You need to define a location before confirming this event.'),
        findsOneWidget,
      );
    });

    testWidgets('shows correct message when only date missing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MissingFieldsConfirmationDialog(
            hasLocation: true,
            hasDate: false,
          ),
        ),
      );

      expect(find.text('Cannot Confirm Event'), findsOneWidget);
      expect(
        find.text('You need to define a date before confirming this event.'),
        findsOneWidget,
      );
    });

    testWidgets('closes dialog when Ok button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          const MissingFieldsConfirmationDialog(
                        hasLocation: false,
                        hasDate: false,
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Cannot Confirm Event'), findsOneWidget);

      // Tap Ok button
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Cannot Confirm Event'), findsNothing);
    });

    testWidgets('dialog is stateless and const-constructible',
        (WidgetTester tester) async {
      // Test that dialog can be created with const constructor
      const dialog = MissingFieldsConfirmationDialog(
        hasLocation: true,
        hasDate: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: dialog,
        ),
      );

      expect(find.byWidget(dialog), findsOneWidget);
    });
  });
}
