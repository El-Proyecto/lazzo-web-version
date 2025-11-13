import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Use case to pin/unpin a chat message
class PinMessage {
  final ChatRepository _repository;

  const PinMessage(this._repository);

  Future<ChatMessage> call(String eventId, String messageId, bool isPinned) {
    return _repository.pinMessage(eventId, messageId, isPinned);
  }
}
