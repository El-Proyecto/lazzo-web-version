import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/event_detail.dart';
import 'package:lazzo/features/event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/event/domain/usecases/get_event_detail.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late GetEventDetail sut;

  setUp(() {
    mockRepository = MockEventRepository();
    sut = GetEventDetail(mockRepository);
  });

  group('GetEventDetail', () {
    test('calls repository and returns event detail', () async {
      // Arrange
      final expected = EventDetail(
        id: 'event-1',
        name: 'Name',
        emoji: '🎉',
        status: EventStatus.pending,
        createdAt: DateTime(2026, 1, 1),
        hostId: 'host-1',
        goingCount: 1,
        notGoingCount: 0,
      );
      when(() => mockRepository.getEventDetail('event-1'))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call('event-1');

      // Assert
      expect(result, expected);
      verify(() => mockRepository.getEventDetail('event-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.getEventDetail(any()))
          .thenThrow(Exception('network'));

      // Act & Assert
      expect(() => sut.call('event-1'), throwsA(isA<Exception>()));
    });
  });
}
