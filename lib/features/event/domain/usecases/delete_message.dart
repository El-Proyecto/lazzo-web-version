import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Use case to delete a chat message
class DeleteMessage {
  final ChatRepository _repository;

  const DeleteMessage(this._repository);

  Future<ChatMessage> call(String messageId) {
    return _repository.deleteMessage(messageId);
  }
}
