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
    final models = await _remoteDataSource.getRecentMessages(
      eventId,
      limit: limit,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<ChatMessage> sendMessage(
    String eventId,
    String userId,
    String content,
  ) async {
    final model = await _remoteDataSource.sendMessage(
      eventId,
      userId,
      content,
    );
    return model.toEntity();
  }

  @override
  Future<List<ChatMessage>> getAllMessages(String eventId) async {
    final models = await _remoteDataSource.getAllMessages(eventId);
    return models.map((model) => model.toEntity()).toList();
  }
}
