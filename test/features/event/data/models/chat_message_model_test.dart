import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/data/models/chat_message_model.dart';

void main() {
  group('ChatMessageModel', () {
    final fullJson = <String, dynamic>{
      'id': 'msg-1',
      'event_id': 'event-1',
      'user_id': 'user-1',
      'content': 'Ola',
      'created_at': '2025-06-15T20:00:00.000Z',
      'is_read_by_someone': true,
      'is_pinned': true,
      'is_deleted': false,
      'reply_to_id': 'msg-0',
      'user': {
        'name': 'Alice',
        'avatar_url': 'https://example.com/alice.jpg',
      },
    };

    test('fromJson parses full row with nested user join', () {
      final model = ChatMessageModel.fromJson(fullJson);

      expect(model.userName, 'Alice');
      expect(model.userAvatar, 'https://example.com/alice.jpg');
      expect(model.isReadBySomeone, isTrue);
      expect(model.isPinned, isTrue);
      expect(model.isDeleted, isFalse);
      expect(model.replyToId, 'msg-0');
    });

    test('fromJson falls back to flat user_name and user_avatar columns', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..remove('user')
        ..['user_name'] = 'RPC User'
        ..['user_avatar'] = 'rpc-avatar.png';

      final model = ChatMessageModel.fromJson(json);
      expect(model.userName, 'RPC User');
      expect(model.userAvatar, 'rpc-avatar.png');
    });

    test('fromJson uses is_read_by_someone then falls back to read', () {
      final fallbackJson = Map<String, dynamic>.from(fullJson)
        ..remove('is_read_by_someone')
        ..['read'] = true;

      final model = ChatMessageModel.fromJson(fallbackJson);
      expect(model.isReadBySomeone, isTrue);
    });

    test('fromJson defaults is_pinned and is_deleted to false when absent', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..remove('is_pinned')
        ..remove('is_deleted');

      final model = ChatMessageModel.fromJson(json);
      expect(model.isPinned, isFalse);
      expect(model.isDeleted, isFalse);
    });

    test('toEntity sets replyTo as null', () {
      final entity = ChatMessageModel.fromJson(fullJson).toEntity();
      expect(entity.replyTo, isNull);
    });

    test('toJson omits reply_to_id when null', () {
      final json = ChatMessageModel.fromJson(
        Map<String, dynamic>.from(fullJson)..['reply_to_id'] = null,
      ).toJson();

      expect(json.containsKey('reply_to_id'), isFalse);
    });
  });
}
