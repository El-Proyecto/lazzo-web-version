import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/event_detail.dart';
import 'package:lazzo/features/event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/event/domain/usecases/extend_event_time.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late ExtendEventTime sut;

  setUp(() {
    mockRepository = MockEventRepository();
    sut = ExtendEventTime(mockRepository);
  });

  group('ExtendEventTime', () {
    test('calls repository and returns event detail', () async {
      // Arrange
      final expected = EventDetail(
        id: 'event-1',
        name: 'Event',
        emoji: '🎉',
        status: EventStatus.living,
        createdAt: DateTime(2026, 1, 1),
        hostId: 'host-1',
        goingCount: 1,
        notGoingCount: 0,
      );
      when(() => mockRepository.extendEventTime('event-1', 15))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call('event-1', 15);

      // Assert
      expect(result, expected);
      verify(() => mockRepository.extendEventTime('event-1', 15)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
