import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/domain/entities/event.dart';
import 'package:lazzo/features/create_event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/create_event/domain/usecases/update_event.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late UpdateEventUseCase sut;
  late Event existingEvent;

  setUpAll(() {
    registerFallbackValue(
      Event(
        id: 'fallback',
        name: 'Fallback',
        emoji: '🎯',
        status: EventStatus.pending,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockRepository = MockEventRepository();
    sut = UpdateEventUseCase(mockRepository);
    existingEvent = Event(
      id: 'event-1',
      name: 'Old',
      emoji: '🎉',
      status: EventStatus.pending,
      createdAt: DateTime(2026, 1, 1),
    );
  });

  group('UpdateEventUseCase', () {
    test('throws ArgumentError when name is empty', () {
      // Act & Assert
      expect(
        () => sut.execute(eventId: 'event-1', name: ' ', emoji: '🎉'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when endDateTime is before startDateTime', () {
      // Arrange
      final startDateTime = DateTime(2026, 1, 1, 10);
      final endDateTime = DateTime(2026, 1, 1, 9);

      // Act & Assert
      expect(
        () => sut.execute(
          eventId: 'event-1',
          name: 'Name',
          emoji: '🎉',
          startDateTime: startDateTime,
          endDateTime: endDateTime,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when event is not found', () {
      // Arrange
      when(() => mockRepository.getEventById('missing'))
          .thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => sut.execute(eventId: 'missing', name: 'Name', emoji: '🎉'),
        throwsA(
          isA<ArgumentError>().having((e) => e.message, 'message', 'Event not found'),
        ),
      );
    });

    test('updates successfully with nullable fields set to null', () async {
      // Arrange
      when(() => mockRepository.getEventById('event-1'))
          .thenAnswer((_) async => existingEvent);
      when(() => mockRepository.updateEvent(any())).thenAnswer(
        (invocation) async => invocation.positionalArguments.first as Event,
      );

      // Act
      final result = await sut.execute(
        eventId: 'event-1',
        name: 'New Name',
        emoji: '📍',
        startDateTime: null,
        endDateTime: null,
        location: null,
        description: null,
      );

      // Assert
      expect(result.name, 'New Name');
      verify(() => mockRepository.getEventById('event-1')).called(1);
      verify(() => mockRepository.updateEvent(any(that: isA<Event>()))).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.getEventById('event-1'))
          .thenThrow(Exception('db'));

      // Act & Assert
      expect(
        () => sut.execute(eventId: 'event-1', name: 'Name', emoji: '🎉'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
