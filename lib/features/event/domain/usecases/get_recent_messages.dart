import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Use case to get recent chat messages
class GetRecentMessages {
  final ChatRepository repository;

  const GetRecentMessages(this.repository);

  Future<List<ChatMessage>> call(String eventId, {int limit = 2}) async {
    return await repository.getRecentMessages(eventId, limit: limit);
  }
}
