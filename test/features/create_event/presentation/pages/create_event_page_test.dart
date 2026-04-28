import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/domain/entities/event.dart';
import 'package:lazzo/features/create_event/domain/entities/event_history.dart';
import 'package:lazzo/features/create_event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/create_event/presentation/pages/create_event_page.dart';
import 'package:lazzo/features/create_event/presentation/providers/event_providers.dart';
import 'package:lazzo/features/create_event/presentation/widgets/confirm_event_dialog.dart';
import 'package:lazzo/features/create_event/presentation/widgets/location_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateEventRepository extends Mock implements EventRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCreateEventRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      Event(
        id: 'fallback',
        name: 'fallback',
        emoji: '🗓️',
        status: EventStatus.pending,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockRepository = MockCreateEventRepository();
    when(() => mockRepository.createEvent(any())).thenAnswer(
      (_) async => Event(
        id: 'evt-1',
        name: 'Churrasco no Parque',
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
      ),
    );
    when(() => mockRepository.deleteEvent(any())).thenAnswer((_) async {});
    when(() => mockRepository.getCurrentLocation()).thenAnswer((_) async => null);
    when(() => mockRepository.getEventById(any())).thenAnswer((_) async => null);
    when(() => mockRepository.searchLocations(any())).thenAnswer((_) async => []);
    when(() => mockRepository.updateEvent(any())).thenAnswer((i) async => i.positionalArguments.first as Event);
    when(() => mockRepository.getUserEventHistory(userId: any(named: 'userId'), limit: any(named: 'limit')))
        .thenAnswer((_) async => <EventHistory>[]);
  });

  group('CreateEventPage', () {
    testWidgets('continue without name shows validation error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [eventRepositoryProvider.overrideWithValue(mockRepository)],
          child: const MaterialApp(home: CreateEventPage()),
        ),
      );

      final continueBtn = find.byKey(const Key('continue_button'));
      await tester.scrollUntilVisible(continueBtn, 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Event name is required'), findsOneWidget);
      expect(find.byType(ConfirmEventBottomSheet), findsNothing);
    });
  });

  group('CreateEvent confirmation bottom sheet', () {
    Future<void> pumpBottomSheet(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [eventRepositoryProvider.overrideWithValue(mockRepository)],
          child: MaterialApp(
            home: ConfirmEventBottomSheet(
              eventName: 'Churrasco no Parque',
              eventEmoji: '🍖',
              selectedDate: DateTime.now().add(const Duration(days: 1)),
              selectedTime: const TimeOfDay(hour: 18, minute: 0),
              endDate: DateTime.now().add(const Duration(days: 1)),
              endTime: const TimeOfDay(hour: 21, minute: 0),
              selectedLocation: const LocationInfo(
                id: 'loc-1',
                displayName: 'Parque',
                formattedAddress: 'Parque da Cidade',
                latitude: 0,
                longitude: 0,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('valid name shows ConfirmEventBottomSheet', (tester) async {
      await pumpBottomSheet(tester);
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmEventBottomSheet), findsOneWidget);
      expect(find.text('Confirm Event'), findsOneWidget);
      expect(find.textContaining('Churrasco no Parque'), findsOneWidget);
    });

    testWidgets('loading state shows a progress indicator', (tester) async {
      final completer = Completer<Event>();
      when(() => mockRepository.createEvent(any())).thenAnswer((_) => completer.future);

      await pumpBottomSheet(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Creating...'), findsOneWidget);
    });

    testWidgets('error state from provider shows error message', (tester) async {
      when(() => mockRepository.createEvent(any())).thenThrow(Exception('create-fail'));

      await pumpBottomSheet(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
      await tester.pump(const Duration(seconds: 4));

      expect(find.textContaining('Error creating event:'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
