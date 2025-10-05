import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

/// Fake chat repository for development
class FakeChatRepository implements ChatRepository {
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'msg-1',
      eventId: 'event-1',
      userId: 'user-2',
      userName: 'Maria Santos',
      userAvatar: null,
      content: 'Mal posso esperar! 🔥',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    ChatMessage(
      id: 'msg-2',
      eventId: 'event-1',
      userId: 'user-1',
      userName: 'João Silva',
      userAvatar: null,
      content: 'Vou levar a grelha grande!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  @override
  Future<List<ChatMessage>> getRecentMessages(
    String eventId, {
    int limit = 2,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _messages
        .where((m) => m.eventId == eventId)
        .take(limit)
        .toList()
        .reversed
        .toList();
  }

  @override
  Future<ChatMessage> sendMessage(
    String eventId,
    String userId,
    String content,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final message = ChatMessage(
      id: 'msg-${_messages.length + 1}',
      eventId: eventId,
      userId: userId,
      userName: 'Current User',
      content: content,
      createdAt: DateTime.now(),
    );

    _messages.add(message);
    return message;
  }

  @override
  Future<List<ChatMessage>> getAllMessages(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _messages
        .where((m) => m.eventId == eventId)
        .toList()
        .reversed
        .toList();
  }
}
