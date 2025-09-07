import '../repositories/pending_event_repository.dart';

class VoteOnEvent {
  final PendingEventRepository repo;
  VoteOnEvent(this.repo);

  Future<bool> call(String eventId, String userId, bool isYes) =>
      repo.voteOnEvent(eventId, userId, isYes);
}
