import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazzo/features/event/domain/entities/event_detail.dart';
import 'package:lazzo/features/event/domain/entities/rsvp.dart';
import 'package:lazzo/features/event/domain/repositories/rsvp_repository.dart';
import 'package:lazzo/features/event/presentation/pages/event_page.dart';
import 'package:lazzo/features/event/presentation/providers/event_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockRsvpRepository extends Mock implements RsvpRepository {}

void main() {
  late MockRsvpRepository mockRsvpRepository;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(RsvpStatus.pending);
    try {
      await Supabase.initialize(url: 'https://example.com', anonKey: 'anon-key');
    } catch (_) {}
  });

  setUp(() {
    mockRsvpRepository = MockRsvpRepository();
    when(() => mockRsvpRepository.getEventRsvps('evt-1')).thenAnswer((_) async => []);
    when(() => mockRsvpRepository.getUserRsvp('evt-1', 'user-1')).thenAnswer((_) async => null);
    when(() => mockRsvpRepository.getRsvpsByStatus('evt-1', any())).thenAnswer((_) async => []);
    when(() => mockRsvpRepository.submitRsvp('evt-1', 'user-1', any())).thenAnswer(
      (_) async => Rsvp(
        id: 'r-1',
        eventId: 'evt-1',
        userId: 'user-1',
        userName: 'User',
        status: RsvpStatus.going,
        createdAt: DateTime.now(),
      ),
    );
    when(() => mockRsvpRepository.resetRsvpVotesFromSuggestion('evt-1', any()))
        .thenAnswer((_) async {});
  });

  EventDetail makeEvent({EventStatus status = EventStatus.pending}) {
    return EventDetail(
      id: 'evt-1',
      name: 'Churrascada',
      emoji: '🍖',
      startDateTime: DateTime.now().add(const Duration(days: 1)),
      endDateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      location: const EventLocation(
        id: 'loc-1',
        displayName: 'Parque',
        formattedAddress: 'Parque da Cidade',
        latitude: 0,
        longitude: 0,
      ),
      status: status,
      createdAt: DateTime.now(),
      hostId: 'host-1',
      goingCount: 0,
      notGoingCount: 0,
    );
  }

  List<Override> baseOverrides(EventDetail event) {
    return [
      currentUserIdProvider.overrideWithValue('user-1'),
      eventDetailProvider.overrideWith((ref, eventId) async => event),
      canManageEventProvider.overrideWith((ref, eventId) async => false),
      eventRsvpsProvider.overrideWith((ref, eventId) async => []),
      rsvpRepositoryProvider.overrideWithValue(mockRsvpRepository),
      eventPollsProvider.overrideWith((ref, eventId) async => []),
      eventSuggestionsProvider.overrideWith((ref, eventId) async => []),
      suggestionVotesProvider.overrideWith((ref, eventId) async => []),
      userSuggestionVotesProvider.overrideWith((ref, eventId) async => []),
      eventLocationSuggestionsProvider.overrideWith((ref, eventId) async => []),
      locationSuggestionVotesProvider.overrideWith((ref, eventId) async => []),
      userLocationSuggestionVotesProvider.overrideWith((ref, eventId) async => []),
      guestRsvpListProvider.overrideWith((ref, eventId) async => []),
    ];
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    required List<Override> overrides,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(
          home: EventPage(eventId: 'evt-1'),
        ),
      ),
    );
  }

  group('EventPage', () {
    testWidgets('shows CircularProgressIndicator while loading', (tester) async {
      final completer = Completer<EventDetail>();

      await pumpPage(
        tester,
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          eventDetailProvider.overrideWith((ref, eventId) => completer.future),
          canManageEventProvider.overrideWith((ref, eventId) async => false),
          eventPollsProvider.overrideWith((ref, eventId) async => []),
          eventSuggestionsProvider.overrideWith((ref, eventId) async => []),
          suggestionVotesProvider.overrideWith((ref, eventId) async => []),
          userSuggestionVotesProvider.overrideWith((ref, eventId) async => []),
          eventLocationSuggestionsProvider.overrideWith((ref, eventId) async => []),
          locationSuggestionVotesProvider.overrideWith((ref, eventId) async => []),
          userLocationSuggestionVotesProvider.overrideWith((ref, eventId) async => []),
          eventRsvpsProvider.overrideWith((ref, eventId) async => []),
          rsvpRepositoryProvider.overrideWithValue(mockRsvpRepository),
          guestRsvpListProvider.overrideWith((ref, eventId) async => []),
        ],
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('shows event name when data is available', (tester) async {
      await pumpPage(
        tester,
        overrides: baseOverrides(makeEvent()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Churrascada'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('shows RSVP section for events in pending status', (tester) async {
      await pumpPage(
        tester,
        overrides: baseOverrides(makeEvent(status: EventStatus.pending)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Can'), findsOneWidget);
      expect(find.text('Maybe'), findsOneWidget);
      expect(find.text("Can't"), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('shows error UI when event detail fails', (tester) async {
      await pumpPage(
        tester,
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          eventDetailProvider.overrideWith(
            (ref, eventId) async => throw Exception('event failed'),
          ),
          canManageEventProvider.overrideWith((ref, eventId) async => false),
          eventRsvpsProvider.overrideWith((ref, eventId) async => []),
          rsvpRepositoryProvider.overrideWithValue(mockRsvpRepository),
          eventPollsProvider.overrideWith((ref, eventId) async => []),
          eventSuggestionsProvider.overrideWith((ref, eventId) async => []),
          suggestionVotesProvider.overrideWith((ref, eventId) async => []),
          userSuggestionVotesProvider.overrideWith((ref, eventId) async => []),
          eventLocationSuggestionsProvider.overrideWith((ref, eventId) async => []),
          locationSuggestionVotesProvider.overrideWith((ref, eventId) async => []),
          userLocationSuggestionVotesProvider.overrideWith((ref, eventId) async => []),
          guestRsvpListProvider.overrideWith((ref, eventId) async => []),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Error loading event'), findsOneWidget);
      expect(find.textContaining('event failed'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
