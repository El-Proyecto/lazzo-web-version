import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/data/fakes/fake_chat_repository.dart';
import 'package:lazzo/features/event/domain/entities/chat_message.dart';
import 'package:lazzo/features/event/domain/repositories/chat_repository.dart';

void main() {
  // ignore: unused_local_variable
  final ChatRepository _ = FakeChatRepository();

  late FakeChatRepository repo;

  setUp(() {
    repo = FakeChatRepository();
  });

  group('FakeChatRepository', () {
    test('sendMessage returns ChatMessage with correct content', () async {
      final message = await repo.sendMessage(
        'event-1',
        'current-user',
        'Nova mensagem teste',
      );

      expect(message, isA<ChatMessage>());
      expect(message.content, 'Nova mensagem teste');
      expect(message.eventId, 'event-1');
    });

    test('watchMessages emits Stream<List<ChatMessage>>', () async {
      final firstBatch = await repo.watchMessages('event-1').first;
      expect(firstBatch, isA<List<ChatMessage>>());
      expect(firstBatch, isNotEmpty);
    });

    test('pinMessage toggles isPinned', () async {
      final pinned = await repo.pinMessage('event-1', 'msg-1', true);
      expect(pinned.isPinned, isTrue);

      final unpinned = await repo.pinMessage('event-1', 'msg-1', false);
      expect(unpinned.isPinned, isFalse);
    });

    test('deleteMessage marks message as deleted', () async {
      final deleted = await repo.deleteMessage('event-1', 'msg-1');

      expect(deleted.isDeleted, isTrue);
      expect(deleted.content, 'Message Deleted');
    });
  });
}
