import '../entities/chat_message.dart';

/// Chat repository interface
/// Defines the contract for chat data operations
abstract class ChatRepository {
  /// Stream of messages for an event (real-time updates)
  Stream<List<ChatMessage>> watchMessages(String eventId);

  /// Send a message
  Future<ChatMessage> sendMessage(
    String eventId,
    String userId,
    String content, {
    ChatMessage? replyTo,
  });

  /// Pin or unpin a message
  Future<ChatMessage> pinMessage(String eventId, String messageId, bool isPinned);

  /// Delete a message (marks as deleted, doesn't remove)
  Future<ChatMessage> deleteMessage(String eventId, String messageId);
}
