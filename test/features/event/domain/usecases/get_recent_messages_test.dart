import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/repositories/chat_repository.dart';
import 'package:lazzo/features/event/domain/usecases/get_recent_messages.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository mockRepository;
  late GetRecentMessages sut;

  setUp(() {
    mockRepository = MockChatRepository();
    sut = GetRecentMessages(mockRepository);
  });

  group('GetRecentMessages', () {
    test('throws UnimplementedError for deprecated use case', () {
      // Act & Assert
      expect(
        () => sut.call('event-1'),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
