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
  Future<ChatMessage> pinMessage(
      String eventId, String messageId, bool isPinned);

  /// Delete a message (marks as deleted, doesn't remove)
  Future<ChatMessage> deleteMessage(String eventId, String messageId);

  /// Update the last message read by current user in an event
  Future<bool> updateLastReadMessage({
    required String eventId,
    required String messageId,
  });

  /// Get count of unread messages for current user in an event
  Future<int> getUnreadMessageCount({
    required String eventId,
    required String currentUserId,
  });

  /// Get messages with read status computed (batch query)
  Future<List<ChatMessage>> getMessagesWithReadStatus({
    required String eventId,
    required String currentUserId,
    int limit = 50,
  });

  /// Fetch older messages for pagination (infinite scroll)
  /// Returns messages older than the given timestamp
  Future<List<ChatMessage>> fetchOlderMessages({
    required String eventId,
    required DateTime olderThan,
    int limit = 30,
  });
}
