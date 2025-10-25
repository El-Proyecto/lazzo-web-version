import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Send a chat message to an event
/// Use case that sends a message and returns the created message entity
class SendChatMessage {
  final ChatRepository repository;

  const SendChatMessage(this.repository);

  Future<ChatMessage> call(
    String eventId,
    String userId,
    String content, {
    ChatMessage? replyTo,
  }) async {
    return repository.sendMessage(
      eventId,
      userId,
      content,
      replyTo: replyTo,
    );
  }
}
