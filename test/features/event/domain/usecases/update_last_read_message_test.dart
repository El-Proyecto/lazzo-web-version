import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/repositories/chat_repository.dart';
import 'package:lazzo/features/event/domain/usecases/update_last_read_message.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository mockRepository;
  late UpdateLastReadMessage sut;

  setUp(() {
    mockRepository = MockChatRepository();
    sut = UpdateLastReadMessage(mockRepository);
  });

  group('UpdateLastReadMessage', () {
    test('returns repository result on success', () async {
      // Arrange
      when(
        () => mockRepository.updateLastReadMessage(
          eventId: 'event-1',
          messageId: 'm-1',
        ),
      ).thenAnswer((_) async => true);

      // Act
      final result = await sut.call(eventId: 'event-1', messageId: 'm-1');

      // Assert
      expect(result, isTrue);
      verify(
        () => mockRepository.updateLastReadMessage(
          eventId: 'event-1',
          messageId: 'm-1',
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('returns false when repository throws', () async {
      // Arrange
      when(
        () => mockRepository.updateLastReadMessage(
          eventId: any(named: 'eventId'),
          messageId: any(named: 'messageId'),
        ),
      ).thenThrow(Exception('network'));

      // Act
      final result = await sut.call(eventId: 'event-1', messageId: 'm-1');

      // Assert
      expect(result, isFalse);
      verify(
        () => mockRepository.updateLastReadMessage(
          eventId: 'event-1',
          messageId: 'm-1',
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
