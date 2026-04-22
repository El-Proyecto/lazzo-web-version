import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/repositories/chat_repository.dart';
import 'package:lazzo/features/event/domain/usecases/get_unread_message_count.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository mockRepository;
  late GetUnreadMessageCount sut;

  setUp(() {
    mockRepository = MockChatRepository();
    sut = GetUnreadMessageCount(mockRepository);
  });

  group('GetUnreadMessageCount', () {
    test('returns repository count on success', () async {
      // Arrange
      when(
        () => mockRepository.getUnreadMessageCount(
          eventId: 'event-1',
          currentUserId: 'user-1',
        ),
      ).thenAnswer((_) async => 7);

      // Act
      final result = await sut.call(eventId: 'event-1', currentUserId: 'user-1');

      // Assert
      expect(result, 7);
      verify(
        () => mockRepository.getUnreadMessageCount(
          eventId: 'event-1',
          currentUserId: 'user-1',
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('returns 0 when repository throws', () async {
      // Arrange
      when(
        () => mockRepository.getUnreadMessageCount(
          eventId: any(named: 'eventId'),
          currentUserId: any(named: 'currentUserId'),
        ),
      ).thenThrow(Exception('network'));

      // Act
      final result = await sut.call(eventId: 'event-1', currentUserId: 'user-1');

      // Assert
      expect(result, 0);
      verify(
        () => mockRepository.getUnreadMessageCount(
          eventId: 'event-1',
          currentUserId: 'user-1',
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
