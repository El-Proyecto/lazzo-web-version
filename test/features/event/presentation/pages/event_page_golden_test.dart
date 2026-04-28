import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/event_detail.dart';
import 'package:lazzo/features/event/domain/entities/rsvp.dart';
import 'package:lazzo/features/event/domain/entities/suggestion.dart';
import 'package:lazzo/features/event/presentation/pages/event_page.dart';
import 'package:lazzo/features/event/presentation/providers/event_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/golden_test_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('posthog_flutter'), (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
            'com.llfbandit.app_links/events', (_) async => null);
    try {
      await Supabase.initialize(
          url: 'https://example.com', anonKey: 'anon-key');
    } catch (_) {}
  });

  testWidgets('EventPage - loaded state', (tester) async {
    final event = EventDetail(
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
      status: EventStatus.pending,
      createdAt: DateTime.now(),
      hostId: 'host-1',
      goingCount: 0,
      notGoingCount: 0,
    );

    await pumpGoldenWidget(
      tester,
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          eventDetailProvider.overrideWith((ref, eventId) async => event),
          canManageEventProvider.overrideWith((ref, eventId) async => false),
          eventSuggestionsProvider
              .overrideWith((ref, eventId) async => <Suggestion>[]),
          suggestionVotesProvider
              .overrideWith((ref, eventId) async => <SuggestionVote>[]),
          userSuggestionVotesProvider
              .overrideWith((ref, eventId) async => <SuggestionVote>[]),
          eventLocationSuggestionsProvider
              .overrideWith((ref, eventId) async => <LocationSuggestion>[]),
          locationSuggestionVotesProvider
              .overrideWith((ref, eventId) async => <SuggestionVote>[]),
          userLocationSuggestionVotesProvider
              .overrideWith((ref, eventId) async => <SuggestionVote>[]),
          eventRsvpsProvider.overrideWith((ref, eventId) async => <Rsvp>[]),
          dateTimeSuggestionsDataProvider.overrideWith((ref, eventId) async => {
                'suggestions': <Suggestion>[],
                'allVotes': <SuggestionVote>[],
                'userVoteIds': <String>{},
                'goingCount': 0,
              }),
          locationSuggestionsDataProvider.overrideWith((ref, eventId) async => {
                'locationSuggestions': <LocationSuggestion>[],
                'locationVotes': <SuggestionVote>[],
                'userVoteIds': <String>{},
                'goingCount': 0,
              }),
        ],
        child: const MaterialApp(home: EventPage(eventId: 'evt-1')),
      ),
      screenSize: TestScreenSizes.phone,
    );

    await expectLater(
      find.byType(EventPage),
      matchesGoldenFile('goldens/event_page_loaded.png'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
