import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../data_sources/chat_remote_data_source.dart';

/// Implementation of ChatRepository using Supabase
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ChatMessage>> getRecentMessages(
    String eventId, {
    int limit = 2,
  }) async {
    print('🔍 DEBUG ChatRepository: Getting recent messages for eventId=$eventId');
    final models = await _remoteDataSource.getRecentMessages(
      eventId,
      limit: limit,
    );
    final messages = models.map((model) => model.toEntity()).toList();
    print('✅ DEBUG ChatRepository: Got ${messages.length} messages');
    return messages;
  }

  @override
  Future<ChatMessage> sendMessage(
    String eventId,
    String userId,
    String content, {
    ChatMessage? replyTo,
  }) async {
    print('🔍 DEBUG ChatRepository: Sending message to eventId=$eventId, userId=$userId, content="$content"');
    // TODO: Implement replyTo functionality when needed
    final model = await _remoteDataSource.sendMessage(
      eventId,
      userId,
      content,
    );
    final message = model.toEntity();
    print('✅ DEBUG ChatRepository: Message sent with id=${message.id}');
    return message;
  }

  @override
  Future<List<ChatMessage>> getAllMessages(String eventId) async {
    final models = await _remoteDataSource.getAllMessages(eventId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<ChatMessage> pinMessage(String messageId, bool isPinned) async {
    // TODO: Implement pin message functionality
    throw UnimplementedError('Pin message not yet implemented');
  }

  @override
  Future<ChatMessage> deleteMessage(String messageId) async {
    // TODO: Implement delete message functionality
    throw UnimplementedError('Delete message not yet implemented');
  }
}
