import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Get all chat messages for an event
/// Use case that retrieves all messages in chronological order
class GetChatMessages {
  final ChatRepository repository;

  const GetChatMessages(this.repository);

  Future<List<ChatMessage>> call(String eventId) async {
    return repository.getAllMessages(eventId);
  }
}
