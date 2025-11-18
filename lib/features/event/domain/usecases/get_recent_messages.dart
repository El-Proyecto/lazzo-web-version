import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// DEPRECATED: Use chatMessagesProvider (stream-based) instead
/// Use case to get recent chat messages for an event
@Deprecated('Use chatMessagesProvider stream instead')
class GetRecentMessages {
  final ChatRepository repository;

  GetRecentMessages(this.repository);

  Future<List<ChatMessage>> call(String eventId, {int limit = 2}) async {
    throw UnimplementedError('Use chatMessagesProvider stream instead');
  }
}
