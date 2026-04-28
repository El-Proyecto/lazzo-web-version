import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/poll.dart';
import 'package:lazzo/features/event/domain/repositories/poll_repository.dart';
import 'package:lazzo/features/event/domain/usecases/get_event_polls.dart';
import 'package:mocktail/mocktail.dart';

class MockPollRepository extends Mock implements PollRepository {}

void main() {
  late MockPollRepository mockRepository;
  late GetEventPolls sut;

  setUp(() {
    mockRepository = MockPollRepository();
    sut = GetEventPolls(mockRepository);
  });

  group('GetEventPolls', () {
    test('calls repository and returns polls', () async {
      // Arrange
      final expected = [
        Poll(
          id: 'p-1',
          eventId: 'event-1',
          type: PollType.date,
          question: 'When?',
          options: const [],
          createdAt: DateTime(2026, 1, 1),
          createdBy: 'user-1',
        ),
      ];
      when(() => mockRepository.getEventPolls('event-1'))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call('event-1');

      // Assert
      expect(result, expected);
      verify(() => mockRepository.getEventPolls('event-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.getEventPolls(any()))
          .thenThrow(Exception('network'));

      // Act & Assert
      expect(() => sut.call('event-1'), throwsA(isA<Exception>()));
    });
  });
}
