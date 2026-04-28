import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/event_participant_entity.dart';
import 'package:lazzo/features/event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/event/domain/usecases/get_event_participants.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late GetEventParticipants sut;

  setUp(() {
    mockRepository = MockEventRepository();
    sut = GetEventParticipants(mockRepository);
  });

  group('GetEventParticipants', () {
    test('calls repository and returns participants', () async {
      // Arrange
      const expected = [
        EventParticipantEntity(
          userId: 'u1',
          displayName: 'Alice',
          status: 'confirmed',
        ),
      ];
      when(() => mockRepository.getEventParticipants('event-1'))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call('event-1');

      // Assert
      expect(result, expected);
      verify(() => mockRepository.getEventParticipants('event-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.getEventParticipants(any()))
          .thenThrow(Exception('network'));

      // Act & Assert
      expect(() => sut.call('event-1'), throwsA(isA<Exception>()));
    });
  });
}
