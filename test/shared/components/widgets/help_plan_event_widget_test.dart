import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/components/widgets/help_plan_event_widget.dart';

void main() {
  group('HelpPlanEventWidget', () {
    testWidgets(
        'shows correct button text when both fields missing and no suggestions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HelpPlanEventWidget(
              hasLocation: false,
              hasDate: false,
              hasSuggestedLocation: false,
              hasSuggestedDate: false,
              onAddSuggestion: () {},
            ),
          ),
        ),
      );

      expect(find.text('Help plan this event'), findsOneWidget);
      expect(find.text('Add date and place suggestion'), findsOneWidget);
    });

    testWidgets(
        'shows correct button text when only location missing and no location suggestions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HelpPlanEventWidget(
              hasLocation: false,
              hasDate: true,
              hasSuggestedLocation: false,
              hasSuggestedDate: false,
              onAddSuggestion: () {},
            ),
          ),
        ),
      );

      expect(find.text('Help plan this event'), findsOneWidget);
      expect(find.text('Add place suggestion'), findsOneWidget);
    });

    testWidgets(
        'shows correct button text when only date missing and no date suggestions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HelpPlanEventWidget(
              hasLocation: true,
              hasDate: false,
              hasSuggestedLocation: false,
              hasSuggestedDate: false,
              onAddSuggestion: () {},
            ),
          ),
        ),
      );

      expect(find.text('Help plan this event'), findsOneWidget);
      expect(find.text('Add date suggestion'), findsOneWidget);
    });

    testWidgets(
        'shows place suggestion when date is suggested but location is not',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HelpPlanEventWidget(
              hasLocation: false,
              hasDate: false,
              hasSuggestedLocation: false,
              hasSuggestedDate: true, // Date suggested
              onAddSuggestion: () {},
            ),
          ),
        ),
      );

      expect(find.text('Add place suggestion'), findsOneWidget);
    });

    testWidgets(
        'shows date suggestion when location is suggested but date is not',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HelpPlanEventWidget(
              hasLocation: false,
              hasDate: false,
              hasSuggestedLocation: true, // Location suggested
              hasSuggestedDate: false,
              onAddSuggestion: () {},
            ),
          ),
        ),
      );

      expect(find.text('Add date suggestion'), findsOneWidget);
    });

    testWidgets('calls onAddSuggestion when button is tapped',
        (WidgetTester tester) async {
      bool wasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HelpPlanEventWidget(
              hasLocation: false,
              hasDate: false,
              hasSuggestedLocation: false,
              hasSuggestedDate: false,
              onAddSuggestion: () {
                wasCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add date and place suggestion'));
      await tester.pump();

      expect(wasCalled, true);
    });

    testWidgets('widget is stateless and const-constructible',
        (WidgetTester tester) async {
      // Test that widget can be created with const constructor
      const widget = HelpPlanEventWidget(
        hasLocation: true,
        hasDate: false,
        hasSuggestedLocation: false,
        hasSuggestedDate: false,
        onAddSuggestion: _dummyCallback,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      expect(find.byWidget(widget), findsOneWidget);
    });
  });
}

// Dummy callback for const constructor test
void _dummyCallback() {}
