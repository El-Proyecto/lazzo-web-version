import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lazzo/features/create_event/domain/entities/event.dart';
import 'package:lazzo/features/create_event/domain/entities/event_history.dart';
import 'package:lazzo/features/create_event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/create_event/presentation/pages/create_event_page.dart';
import 'package:lazzo/features/create_event/presentation/providers/event_providers.dart';
import 'package:lazzo/shared/components/cards/event_full_card.dart';
import 'package:lazzo/shared/components/cards/event_small_card.dart';
import 'package:lazzo/shared/components/cards/home_event_card.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/integration_helpers.dart';

class MockCreateEventRepository extends Mock implements EventRepository {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('posthog_flutter'), (_) async => null);
  registerFallbackValue(
    Event(
      id: 'fallback',
      name: 'fallback',
      emoji: '🗓️',
      status: EventStatus.pending,
      createdAt: DateTime(2026, 1, 1),
    ),
  );

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

  group('Smoke - Home and Create Event', () {
    testWidgets('event list page loads with cards', (tester) async {
      await launchAppAndSettle(tester);

      final navigator =
          tester.state<NavigatorState>(find.byType(Navigator).first);
      navigator.pushNamed('/main');
      await tester.pumpAndSettle(const Duration(seconds: 6));

      final hasAnyEventCard =
          find.byType(HomeEventCard).evaluate().isNotEmpty ||
              find.byType(EventSmallCard).evaluate().isNotEmpty ||
              find.byType(EventFullCard).evaluate().isNotEmpty;
      final hasEmptyState =
          find.textContaining('No plans coming up').evaluate().isNotEmpty;

      expect(hasAnyEventCard || hasEmptyState, isTrue);
    });

    testWidgets('create event flow reaches confirm and submit', (tester) async {
      final mockRepository = MockCreateEventRepository();
      when(() => mockRepository.createEvent(any())).thenAnswer(
        (_) async => Event(
          id: 'evt-ci',
          name: 'CI Event',
          emoji: '🎉',
          startDateTime: DateTime.now().add(const Duration(days: 1)),
          endDateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          location: const EventLocation(
            id: 'loc-ci',
            displayName: 'CI Spot',
            formattedAddress: 'CI Spot',
            latitude: 0,
            longitude: 0,
          ),
          status: EventStatus.pending,
          createdAt: DateTime.now(),
        ),
      );
      when(() => mockRepository.deleteEvent(any())).thenAnswer((_) async {});
      when(() => mockRepository.getCurrentLocation())
          .thenAnswer((_) async => null);
      when(() => mockRepository.getEventById(any()))
          .thenAnswer((_) async => null);
      when(() => mockRepository.searchLocations(any()))
          .thenAnswer((_) async => []);
      when(() => mockRepository.updateEvent(any()))
          .thenAnswer((i) async => i.positionalArguments.first as Event);
      when(
        () => mockRepository.getUserEventHistory(
          userId: any(named: 'userId'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => <EventHistory>[]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockRepository)
          ],
          child: MaterialApp(
            routes: {
              '/': (context) => const CreateEventPage(),
              '/main': (context) => const Scaffold(
                    body: Center(child: Text('Main Loaded')),
                  ),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Location name').first,
        'CI Spot',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Event Name').first);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('createEvent:name')), 'CI Event');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Date').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(DateTime.now().day.toString()).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Time').first);
      await tester.pumpAndSettle();
      await tester.drag(
          find.byType(ListWheelScrollView).first, const Offset(0, -64));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Event'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
      await tester.pump();

      // And then the confirmation sheet closed (successful submit path).
      await tester.pumpAndSettle(const Duration(seconds: 8));
      expect(find.text('Confirm Event'), findsNothing);
      expect(find.text('Main Loaded'), findsOneWidget);

      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
