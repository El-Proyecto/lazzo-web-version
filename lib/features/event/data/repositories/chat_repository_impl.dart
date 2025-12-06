import 'dart:async';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../data_sources/chat_remote_data_source.dart';

/// Implementation of ChatRepository using Supabase
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<ChatMessage>> watchMessages(String eventId) async* {
    await for (final models in _remoteDataSource.watchMessages(eventId)) {
      // Build a map of all messages by ID for fast lookup (for replyTo)
      final messagesById = <String, ChatMessage>{};

      // First pass: convert all models to entities (without replyTo)
      for (final model in models) {
        messagesById[model.id] = model.toEntity();
      }

      // Second pass: populate replyTo references
      final messagesWithReplies = <ChatMessage>[];
      for (final model in models) {
        final baseMessage = messagesById[model.id]!;

        // If this message has a reply_to_id, find the referenced message
        final replyTo =
            model.replyToId != null ? messagesById[model.replyToId] : null;

        messagesWithReplies.add(baseMessage.copyWith(replyTo: replyTo));
      }

      yield messagesWithReplies;
    }
  }

  /// DEPRECATED: Use watchMessages instead
  Future<List<ChatMessage>> getRecentMessages(
    String eventId, {
    int limit = 2,
  }) async {
    final models = await _remoteDataSource.getRecentMessages(
      eventId,
      limit: limit,
    );

    // Build a map of all messages by ID for fast lookup (for replyTo)
    final messagesById = <String, ChatMessage>{};

    // First pass: convert all models to entities (without replyTo)
    for (final model in models) {
      messagesById[model.id] = model.toEntity();
    }

    // Second pass: populate replyTo references
    final messagesWithReplies = <ChatMessage>[];
    for (final model in models) {
      final baseMessage = messagesById[model.id]!;

      // If this message has a reply_to_id, find the referenced message
      final replyTo =
          model.replyToId != null ? messagesById[model.replyToId] : null;

      if (replyTo != null) {}

      messagesWithReplies.add(baseMessage.copyWith(replyTo: replyTo));
    }

    return messagesWithReplies;
  }

  @override
  Future<ChatMessage> sendMessage(
    String eventId,
    String userId,
    String content, {
    ChatMessage? replyTo,
  }) async {
    final model = await _remoteDataSource.sendMessage(
      eventId,
      userId,
      content,
      replyToId: replyTo?.id,
    );
    final message = model.toEntity();
    return message;
  }

  /// DEPRECATED: Use watchMessages instead
  Future<List<ChatMessage>> getAllMessages(String eventId) async {
    final models = await _remoteDataSource.getAllMessages(eventId);

    // Build a map of all messages by ID for fast lookup
    final messagesById = <String, ChatMessage>{};

    // First pass: convert all models to entities (without replyTo)
    for (final model in models) {
      messagesById[model.id] = model.toEntity();
    }

    // Second pass: populate replyTo references
    final messagesWithReplies = <ChatMessage>[];
    for (final model in models) {
      final baseMessage = messagesById[model.id]!;

      // If this message has a reply_to_id, find the referenced message
      final replyTo =
          model.replyToId != null ? messagesById[model.replyToId] : null;

      if (replyTo != null) {}

      messagesWithReplies.add(baseMessage.copyWith(replyTo: replyTo));
    }

    return messagesWithReplies;
  }

  @override
  Future<ChatMessage> pinMessage(
      String eventId, String messageId, bool isPinned) async {
    await _remoteDataSource.pinMessage(messageId, eventId, isPinned);

    // Reload the message to get updated state
    final updatedMessages = await _remoteDataSource.getAllMessages(eventId);
    final updatedMessage = updatedMessages.firstWhere((m) => m.id == messageId);

    return updatedMessage.toEntity();
  }

  @override
  Future<ChatMessage> deleteMessage(String eventId, String messageId) async {
    await _remoteDataSource.deleteMessage(messageId);

    // Reload to get updated state
    final updatedMessages = await _remoteDataSource.getAllMessages(eventId);
    final updatedMessage = updatedMessages.firstWhere((m) => m.id == messageId);

    return updatedMessage.toEntity();
  }

  @override
  Future<bool> updateLastReadMessage({
    required String eventId,
    required String messageId,
  }) async {
    try {

      final response = await _remoteDataSource.updateLastReadMessage(
        eventId: eventId,
        messageId: messageId,
      );

      final success = response['success'] == true;

      return success;
    } catch (e) {
                  throw Exception('Failed to update last read message: $e');
    }
  }

  @override
  Future<int> getUnreadMessageCount({
    required String eventId,
    required String currentUserId,
  }) async {
    try {

      final count = await _remoteDataSource.getUnreadMessageCount(
        eventId: eventId,
        currentUserId: currentUserId,
      );

      return count;
    } catch (e) {
                  throw Exception('Failed to get unread message count: $e');
    }
  }

  @override
  Future<List<ChatMessage>> getMessagesWithReadStatus({
    required String eventId,
    required String currentUserId,
    int limit = 50,
  }) async {
    try {

      final models = await _remoteDataSource.getMessagesWithReadStatus(
        eventId: eventId,
        currentUserId: currentUserId,
        limit: limit,
      );

      // Build a map of all messages by ID for fast lookup (for replyTo)
      final messagesById = <String, ChatMessage>{};

      // First pass: convert all models to entities (without replyTo)
      for (final model in models) {
        messagesById[model.id] = model.toEntity();
      }

      // Second pass: populate replyTo references
      final messagesWithReplies = <ChatMessage>[];
      for (final model in models) {
        final baseMessage = messagesById[model.id]!;

        // If this message has a reply_to_id, find the referenced message
        final replyTo =
            model.replyToId != null ? messagesById[model.replyToId] : null;

        messagesWithReplies.add(baseMessage.copyWith(replyTo: replyTo));
      }

      return messagesWithReplies;
    } catch (e) {
                  throw Exception('Failed to get messages with read status: $e');
    }
  }
}
