import '../entities/pending_event.dart';
import '../repositories/pending_event_repository.dart';

class GetPendingEvents {
  final PendingEventRepository repo;
  GetPendingEvents(this.repo);

  Future<List<PendingEvent>> call(String userId) =>
      repo.getPendingEvents(userId);
}
