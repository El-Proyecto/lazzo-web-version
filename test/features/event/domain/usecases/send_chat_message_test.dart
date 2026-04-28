import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/chat_message.dart';
import 'package:lazzo/features/event/domain/repositories/chat_repository.dart';
import 'package:lazzo/features/event/domain/usecases/send_chat_message.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository mockRepository;
  late SendChatMessage sut;

  setUp(() {
    mockRepository = MockChatRepository();
    sut = SendChatMessage(mockRepository);
  });

  group('SendChatMessage', () {
    test('calls repository and returns message', () async {
      // Arrange
      final expected = ChatMessage(
        id: 'm-1',
        eventId: 'event-1',
        userId: 'user-1',
        userName: 'Alice',
        content: 'Hello',
        createdAt: DateTime(2026, 1, 1),
      );
      when(() => mockRepository.sendMessage('event-1', 'user-1', 'Hello', replyTo: null))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call('event-1', 'user-1', 'Hello');

      // Assert
      expect(result, expected);
      verify(() => mockRepository.sendMessage('event-1', 'user-1', 'Hello', replyTo: null))
          .called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.sendMessage(any(), any(), any(), replyTo: any(named: 'replyTo')))
          .thenThrow(Exception('network'));

      // Act & Assert
      expect(() => sut.call('event-1', 'user-1', 'Hello'), throwsA(isA<Exception>()));
    });
  });
}
