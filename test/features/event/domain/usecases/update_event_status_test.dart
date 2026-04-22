import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/event_detail.dart';
import 'package:lazzo/features/event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/event/domain/usecases/update_event_status.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late UpdateEventStatus sut;

  setUp(() {
    mockRepository = MockEventRepository();
    sut = UpdateEventStatus(mockRepository);
  });

  group('UpdateEventStatus', () {
    test('calls repository and returns updated event detail', () async {
      // Arrange
      final expected = EventDetail(
        id: 'event-1',
        name: 'Event',
        emoji: '🎉',
        status: EventStatus.confirmed,
        createdAt: DateTime(2026, 1, 1),
        hostId: 'host-1',
        goingCount: 1,
        notGoingCount: 0,
      );
      when(() => mockRepository.updateEventStatus('event-1', EventStatus.confirmed))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call('event-1', EventStatus.confirmed);

      // Assert
      expect(result, expected);
      verify(() => mockRepository.updateEventStatus('event-1', EventStatus.confirmed))
          .called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
