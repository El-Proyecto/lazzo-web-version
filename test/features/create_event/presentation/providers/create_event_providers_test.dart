import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/domain/entities/event.dart';
import 'package:lazzo/features/create_event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/create_event/presentation/providers/event_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

class FakeEvent extends Fake implements Event {}

void main() {
  late MockEventRepository mockEventRepository;

  setUpAll(() {
    registerFallbackValue(FakeEvent());
  });

  setUp(() {
    mockEventRepository = MockEventRepository();
  });

  Event makeEvent({
    required String id,
    required String name,
  }) {
    return Event(
      id: id,
      name: name,
      emoji: 'X',
      status: EventStatus.pending,
      createdAt: DateTime(2025, 1, 1),
    );
  }

  group('CreateEventController', () {
    test('has expected initial state', () {
      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(createEventControllerProvider);

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.createdEvent, isNull);
    });

    test('sets success state after createEvent', () async {
      final inputEvent = makeEvent(id: '', name: 'Party');
      final createdEvent = makeEvent(id: 'event-1', name: 'Party');
      when(() => mockEventRepository.createEvent(any()))
          .thenAnswer((_) async => createdEvent);

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(createEventControllerProvider.notifier);
      await notifier.createEvent(inputEvent);
      final state = container.read(createEventControllerProvider);

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.createdEvent, createdEvent);
      verify(() => mockEventRepository.createEvent(any())).called(1);
    });

    test('sets loading state during in-flight createEvent call', () async {
      final inputEvent = makeEvent(id: '', name: 'Party');
      when(() => mockEventRepository.createEvent(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return makeEvent(id: 'event-1', name: 'Party');
      });

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(createEventControllerProvider.notifier);
      final pending = notifier.createEvent(inputEvent);

      final loadingState = container.read(createEventControllerProvider);
      expect(loadingState.isLoading, isTrue);

      await pending;
      final finalState = container.read(createEventControllerProvider);
      expect(finalState.isLoading, isFalse);
    });

    test('sets error state when createEvent fails', () async {
      final inputEvent = makeEvent(id: '', name: 'Party');
      when(() => mockEventRepository.createEvent(any()))
          .thenThrow(Exception('create-fail'));

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(createEventControllerProvider.notifier);

      await expectLater(
        () => notifier.createEvent(inputEvent),
        throwsA(isA<Exception>()),
      );
      final state = container.read(createEventControllerProvider);

      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
      expect(state.createdEvent, isNull);
    });

    test('guards duplicate createEvent calls while loading', () async {
      final inputEvent = makeEvent(id: '', name: 'Party');
      when(() => mockEventRepository.createEvent(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return makeEvent(id: 'event-1', name: 'Party');
      });

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(createEventControllerProvider.notifier);
      final firstCall = notifier.createEvent(inputEvent);
      final secondCall = notifier.createEvent(inputEvent);

      await Future.wait([firstCall, secondCall]);

      verify(() => mockEventRepository.createEvent(any())).called(1);
      verifyNoMoreInteractions(mockEventRepository);
    });
  });

  group('EditEventController', () {
    test('updateEvent success sets updatedEvent and clears error', () async {
      final updatedEvent = makeEvent(id: 'event-1', name: 'Party Updated');
      when(() => mockEventRepository.getEventById('event-1'))
          .thenAnswer((_) async => makeEvent(id: 'event-1', name: 'Party'));
      when(() => mockEventRepository.updateEvent(any()))
          .thenAnswer((_) async => updatedEvent);

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(editEventControllerProvider.notifier);
      await notifier.updateEvent(
        eventId: 'event-1',
        name: 'Party Updated',
        emoji: 'X',
      );
      final state = container.read(editEventControllerProvider);

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.updatedEvent, updatedEvent);
    });

    test('updateEvent failure sets error', () async {
      when(() => mockEventRepository.getEventById('event-1'))
          .thenAnswer((_) async => makeEvent(id: 'event-1', name: 'Party'));
      when(() => mockEventRepository.updateEvent(any()))
          .thenThrow(Exception('update-fail'));

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(editEventControllerProvider.notifier);
      await notifier.updateEvent(
        eventId: 'event-1',
        name: 'Party Updated',
        emoji: 'X',
      );
      final state = container.read(editEventControllerProvider);

      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('deleteEvent success sets isDeleted true', () async {
      when(() => mockEventRepository.getEventById('event-1'))
          .thenAnswer((_) async => makeEvent(id: 'event-1', name: 'Party'));
      when(() => mockEventRepository.deleteEvent('event-1'))
          .thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(editEventControllerProvider.notifier);
      await notifier.deleteEvent('event-1');
      final state = container.read(editEventControllerProvider);

      expect(state.isDeleting, isFalse);
      expect(state.isDeleted, isTrue);
      expect(state.error, isNull);
    });

    test('deleteEvent failure sets error', () async {
      when(() => mockEventRepository.getEventById('event-1'))
          .thenAnswer((_) async => makeEvent(id: 'event-1', name: 'Party'));
      when(() => mockEventRepository.deleteEvent('event-1'))
          .thenThrow(Exception('delete-fail'));

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(editEventControllerProvider.notifier);
      await expectLater(
        () => notifier.deleteEvent('event-1'),
        throwsA(isA<Exception>()),
      );
      final state = container.read(editEventControllerProvider);

      expect(state.isDeleting, isFalse);
      expect(state.error, isNotNull);
    });
  });
}
