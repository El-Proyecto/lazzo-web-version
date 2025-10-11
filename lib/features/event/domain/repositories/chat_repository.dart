import '../entities/chat_message.dart';

/// Chat repository interface
/// Defines the contract for chat data operations
abstract class ChatRepository {
  /// Get recent messages for an event
  Future<List<ChatMessage>> getRecentMessages(String eventId, {int limit = 2});

  /// Send a message
  Future<ChatMessage> sendMessage(
    String eventId,
    String userId,
    String content,
  );

  /// Get all messages for an event
  Future<List<ChatMessage>> getAllMessages(String eventId);
}
