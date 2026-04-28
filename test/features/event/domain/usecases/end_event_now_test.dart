import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/event_detail.dart';
import 'package:lazzo/features/event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/event/domain/usecases/end_event_now.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late EndEventNow sut;

  setUp(() {
    mockRepository = MockEventRepository();
    sut = EndEventNow(mockRepository);
  });

  group('EndEventNow', () {
    test('calls repository and returns event detail', () async {
      // Arrange
      final expected = EventDetail(
        id: 'event-1',
        name: 'Event',
        emoji: '🎉',
        status: EventStatus.ended,
        createdAt: DateTime(2026, 1, 1),
        hostId: 'host-1',
        goingCount: 1,
        notGoingCount: 0,
      );
      when(() => mockRepository.endEventNow('event-1'))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call('event-1');

      // Assert
      expect(result, expected);
      verify(() => mockRepository.endEventNow('event-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
