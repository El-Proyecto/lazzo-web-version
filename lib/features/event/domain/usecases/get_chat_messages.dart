import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// DEPRECATED: Use chatMessagesProvider (stream-based) instead
/// Get all chat messages for an event
/// Use case that retrieves all messages in chronological order
@Deprecated('Use chatMessagesProvider stream instead')
class GetChatMessages {
  final ChatRepository repository;

  const GetChatMessages(this.repository);

  Future<List<ChatMessage>> call(String eventId) async {
    throw UnimplementedError('Use chatMessagesProvider stream instead');
  }
}
