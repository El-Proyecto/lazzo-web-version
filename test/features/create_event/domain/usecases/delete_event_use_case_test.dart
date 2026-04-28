import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/domain/entities/event.dart';
import 'package:lazzo/features/create_event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/create_event/domain/usecases/delete_event.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late DeleteEventUseCase sut;

  setUp(() {
    mockRepository = MockEventRepository();
    sut = DeleteEventUseCase(mockRepository);
  });

  group('DeleteEventUseCase', () {
    test('throws ArgumentError when eventId is empty', () {
      // Act & Assert
      expect(() => sut.execute('   '), throwsA(isA<ArgumentError>()));
    });

    test('throws ArgumentError when event is not found', () {
      // Arrange
      when(() => mockRepository.getEventById('event-1'))
          .thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => sut.execute('event-1'),
        throwsA(
          isA<ArgumentError>().having((e) => e.message, 'message', 'Event not found'),
        ),
      );
    });

    test('calls deleteEvent with correct id on happy path', () async {
      // Arrange
      final existing = Event(
        id: 'event-1',
        name: 'Event',
        emoji: '🎉',
        status: EventStatus.pending,
        createdAt: DateTime(2026, 1, 1),
      );
      when(() => mockRepository.getEventById('event-1'))
          .thenAnswer((_) async => existing);
      when(() => mockRepository.deleteEvent('event-1')).thenAnswer((_) async {});

      // Act
      await sut.execute('event-1');

      // Assert
      verify(() => mockRepository.getEventById('event-1')).called(1);
      verify(() => mockRepository.deleteEvent('event-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.getEventById('event-1'))
          .thenThrow(Exception('db'));

      // Act & Assert
      expect(() => sut.execute('event-1'), throwsA(isA<Exception>()));
    });
  });
}
