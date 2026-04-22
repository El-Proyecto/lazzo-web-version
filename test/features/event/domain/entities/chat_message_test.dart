import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/chat_message.dart';

void main() {
  final baseMessage = ChatMessage(
    id: 'm-1',
    eventId: 'e-1',
    userId: 'u-1',
    userName: 'Ana',
    content: 'hello',
    createdAt: DateTime(2025, 7, 1),
  );

  group('ChatMessage', () {
    test('isPending defaults to false', () {
      expect(baseMessage.isPending, isFalse);
    });

    test('copyWith updates isPinned', () {
      final updated = baseMessage.copyWith(isPinned: true);
      expect(updated.isPinned, isTrue);
    });

    test('copyWith updates isDeleted', () {
      final updated = baseMessage.copyWith(isDeleted: true);
      expect(updated.isDeleted, isTrue);
    });

    test('copyWith sets nested replyTo message', () {
      final parent = ChatMessage(
        id: 'm-parent',
        eventId: 'e-1',
        userId: 'u-2',
        userName: 'Bia',
        content: 'parent',
        createdAt: DateTime(2025, 7, 1, 10),
      );

      final reply = baseMessage.copyWith(replyTo: parent);

      expect(reply.replyTo, isNotNull);
      expect(reply.replyTo?.id, 'm-parent');
    });
  });
}
