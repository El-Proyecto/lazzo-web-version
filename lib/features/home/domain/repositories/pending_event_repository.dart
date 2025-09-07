import '../entities/pending_event.dart';

abstract class PendingEventRepository {
  Future<List<PendingEvent>> getPendingEvents(String userId);
  Future<bool> voteOnEvent(String eventId, String userId, bool isYes);
}
