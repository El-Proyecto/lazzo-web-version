import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/chat_message.dart';
import 'package:lazzo/features/event/domain/repositories/chat_repository.dart';
import 'package:lazzo/features/event/domain/usecases/delete_message.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository mockRepository;
  late DeleteMessage sut;

  setUp(() {
    mockRepository = MockChatRepository();
    sut = DeleteMessage(mockRepository);
  });

  group('DeleteMessage', () {
    test('calls repository and returns message', () async {
      // Arrange
      final expected = ChatMessage(
        id: 'm-1',
        eventId: 'event-1',
        userId: 'user-1',
        userName: 'Alice',
        content: 'deleted',
        createdAt: DateTime(2026, 1, 1),
        isDeleted: true,
      );
      when(() => mockRepository.deleteMessage('event-1', 'm-1'))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call('event-1', 'm-1');

      // Assert
      expect(result, expected);
      verify(() => mockRepository.deleteMessage('event-1', 'm-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.deleteMessage(any(), any()))
          .thenThrow(Exception('network'));

      // Act & Assert
      expect(() => sut.call('event-1', 'm-1'), throwsA(isA<Exception>()));
    });
  });
}
