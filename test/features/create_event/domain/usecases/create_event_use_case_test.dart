import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/domain/entities/event.dart';
import 'package:lazzo/features/create_event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/create_event/domain/usecases/create_event.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late CreateEventUseCase sut;

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
    sut = CreateEventUseCase(mockRepository);
  });

  group('CreateEventUseCase', () {
    test('throws ArgumentError when name is empty', () {
      // Act & Assert
      expect(
        () => sut.execute(name: '', emoji: '🎉'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when name is only whitespace', () {
      // Act & Assert
      expect(
        () => sut.execute(name: '   ', emoji: '🎉'),
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
          name: 'Event',
          emoji: '🎉',
          startDateTime: startDateTime,
          endDateTime: endDateTime,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when endDateTime equals startDateTime', () {
      // Arrange
      final dateTime = DateTime(2026, 1, 1, 10);

      // Act & Assert
      expect(
        () => sut.execute(
          name: 'Event',
          emoji: '🎉',
          startDateTime: dateTime,
          endDateTime: dateTime,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('succeeds with optional fields null', () async {
      // Arrange
      final createdEvent = Event(
        id: 'event-1',
        name: 'My Event',
        emoji: '🎉',
        status: EventStatus.pending,
        createdAt: DateTime(2026, 1, 1),
      );
      when(() => mockRepository.createEvent(any()))
          .thenAnswer((_) async => createdEvent);

      // Act
      final result = await sut.execute(name: '  My Event  ', emoji: '🎉');

      // Assert
      expect(result, createdEvent);
      verify(() => mockRepository.createEvent(any(that: isA<Event>())))
          .called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('succeeds with all fields provided', () async {
      // Arrange
      final startDateTime = DateTime(2026, 2, 1, 10);
      final endDateTime = DateTime(2026, 2, 1, 12);
      const location = EventLocation(
        id: 'loc-1',
        displayName: 'Cafe',
        formattedAddress: 'Street',
        latitude: 1,
        longitude: 2,
      );
      final createdEvent = Event(
        id: 'event-2',
        name: 'All Fields Event',
        emoji: '📍',
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        location: location,
        status: EventStatus.pending,
        createdAt: DateTime(2026, 2, 1),
        description: 'desc',
      );
      when(() => mockRepository.createEvent(any()))
          .thenAnswer((_) async => createdEvent);

      // Act
      final result = await sut.execute(
        name: 'All Fields Event',
        emoji: '📍',
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        location: location,
        description: 'desc',
      );

      // Assert
      expect(result, createdEvent);
      verify(() => mockRepository.createEvent(any(that: isA<Event>())))
          .called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.createEvent(any()))
          .thenThrow(Exception('storage'));

      // Act & Assert
      expect(
        () => sut.execute(name: 'Valid', emoji: '🎉'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
