import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/event_detail.dart';
import 'package:lazzo/features/event/domain/entities/rsvp.dart';
import 'package:lazzo/features/event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/event/domain/repositories/rsvp_repository.dart';
import 'package:lazzo/features/event/presentation/providers/event_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

class MockRsvpRepository extends Mock implements RsvpRepository {}

void main() {
  late MockEventRepository mockEventRepository;
  late MockRsvpRepository mockRsvpRepository;

  setUpAll(() {
    registerFallbackValue(EventStatus.pending);
    registerFallbackValue(RsvpStatus.pending);
  });

  setUp(() {
    mockEventRepository = MockEventRepository();
    mockRsvpRepository = MockRsvpRepository();
  });

  EventDetail makeEventDetail({required String hostId}) {
    return EventDetail(
      id: 'event-1',
      name: 'BBQ',
      emoji: 'X',
      status: EventStatus.pending,
      createdAt: DateTime(2025, 1, 1),
      hostId: hostId,
      goingCount: 3,
      notGoingCount: 1,
    );
  }

  Rsvp makeRsvp() {
    return Rsvp(
      id: 'rsvp-1',
      eventId: 'event-1',
      userId: 'user-1',
      userName: 'User One',
      status: RsvpStatus.going,
      createdAt: DateTime(2025, 1, 1),
    );
  }

  group('eventDetailProvider', () {
    test('returns EventDetail on success', () async {
      final event = makeEventDetail(hostId: 'host-1');
      when(() => mockEventRepository.getEventDetail('event-1'))
          .thenAnswer((_) async => event);

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(eventDetailProvider('event-1').future);

      expect(result, event);
      verify(() => mockEventRepository.getEventDetail('event-1')).called(1);
      verifyNoMoreInteractions(mockEventRepository);
    });

    test('throws when repository fails', () async {
      when(() => mockEventRepository.getEventDetail(any()))
          .thenThrow(Exception('network'));

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(eventDetailProvider('event-1').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('eventRsvpsProvider', () {
    test('returns RSVP list on success', () async {
      final rsvps = [makeRsvp()];
      when(() => mockRsvpRepository.getEventRsvps('event-1'))
          .thenAnswer((_) async => rsvps);

      final container = ProviderContainer(
        overrides: [
          rsvpRepositoryProvider.overrideWithValue(mockRsvpRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(eventRsvpsProvider('event-1').future);

      expect(result, rsvps);
      verify(() => mockRsvpRepository.getEventRsvps('event-1')).called(1);
      verifyNoMoreInteractions(mockRsvpRepository);
    });

    test('throws when repository fails', () async {
      when(() => mockRsvpRepository.getEventRsvps(any()))
          .thenThrow(Exception('rsvp-fail'));

      final container = ProviderContainer(
        overrides: [
          rsvpRepositoryProvider.overrideWithValue(mockRsvpRepository),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(eventRsvpsProvider('event-1').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('canManageEventProvider', () {
    test('returns true when current user is host', () async {
      when(() => mockEventRepository.getEventDetail('event-1'))
          .thenAnswer((_) async => makeEventDetail(hostId: 'user-1'));

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
          currentUserIdProvider.overrideWithValue('user-1'),
        ],
      );
      addTearDown(container.dispose);

      final result =
          await container.read(canManageEventProvider('event-1').future);

      expect(result, isTrue);
    });

    test('returns false when current user is null', () async {
      when(() => mockEventRepository.getEventDetail('event-1'))
          .thenAnswer((_) async => makeEventDetail(hostId: 'user-1'));

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
          currentUserIdProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final result =
          await container.read(canManageEventProvider('event-1').future);

      expect(result, isFalse);
    });

    test('returns false when current user is not host', () async {
      when(() => mockEventRepository.getEventDetail('event-1'))
          .thenAnswer((_) async => makeEventDetail(hostId: 'host-2'));

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
          currentUserIdProvider.overrideWithValue('user-1'),
        ],
      );
      addTearDown(container.dispose);

      final result =
          await container.read(canManageEventProvider('event-1').future);

      expect(result, isFalse);
    });

    test('returns false when event detail provider fails', () async {
      when(() => mockEventRepository.getEventDetail(any()))
          .thenThrow(Exception('boom'));

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
          currentUserIdProvider.overrideWithValue('user-1'),
        ],
      );
      addTearDown(container.dispose);

      final result =
          await container.read(canManageEventProvider('event-1').future);

      expect(result, isFalse);
    });
  });
}
