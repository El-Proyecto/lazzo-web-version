import '../repositories/chat_repository.dart';

/// Use case: Get count of unread messages for current user in an event
///
/// Used to display badge counts on event cards and group previews.
/// Excludes messages sent by the current user.
class GetUnreadMessageCount {
  final ChatRepository repository;

  GetUnreadMessageCount(this.repository);

  /// Get unread message count for an event
  ///
  /// Returns 0 if there are no unread messages or if an error occurs
  Future<int> call({
    required String eventId,
    required String currentUserId,
  }) async {
    try {

      final count = await repository.getUnreadMessageCount(
        eventId: eventId,
        currentUserId: currentUserId,
      );

      return count;
    } catch (e, stackTrace) {
      print('[GetUnreadMessageCount] Error getting unread count: $e');
      print('  Stack trace: $stackTrace');
      return 0;
    }
  }
}
