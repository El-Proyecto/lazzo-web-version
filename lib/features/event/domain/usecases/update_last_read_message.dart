import '../repositories/chat_repository.dart';

/// Use case: Update the last message read by current user in an event
///
/// This is called when the user opens the chat page to mark all visible
/// messages as read. Only updates if the new message is more recent than
/// the previously recorded last read message.
class UpdateLastReadMessage {
  final ChatRepository repository;

  UpdateLastReadMessage(this.repository);

  /// Update last read message for current user
  ///
  /// Returns true if update was successful
  Future<bool> call({
    required String eventId,
    required String messageId,
  }) async {
    try {

      final success = await repository.updateLastReadMessage(
        eventId: eventId,
        messageId: messageId,
      );

      return success;
    } catch (e, stackTrace) {
      print('[UpdateLastReadMessage] Error updating last read message: $e');
      print('  Stack trace: $stackTrace');
      return false;
    }
  }
}
