import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/chat_message.dart';
import 'package:lazzo/features/event/domain/repositories/chat_repository.dart';
import 'package:lazzo/features/event/domain/usecases/pin_message.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository mockRepository;
  late PinMessage sut;

  setUp(() {
    mockRepository = MockChatRepository();
    sut = PinMessage(mockRepository);
  });

  group('PinMessage', () {
    test('calls repository and returns message', () async {
      // Arrange
      final expected = ChatMessage(
        id: 'm-1',
        eventId: 'event-1',
        userId: 'user-1',
        userName: 'Alice',
        content: 'hello',
        createdAt: DateTime(2026, 1, 1),
        isPinned: true,
      );
      when(() => mockRepository.pinMessage('event-1', 'm-1', true))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call('event-1', 'm-1', true);

      // Assert
      expect(result, expected);
      verify(() => mockRepository.pinMessage('event-1', 'm-1', true)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.pinMessage(any(), any(), any()))
          .thenThrow(Exception('network'));

      // Act & Assert
      expect(() => sut.call('event-1', 'm-1', true), throwsA(isA<Exception>()));
    });
  });
}
