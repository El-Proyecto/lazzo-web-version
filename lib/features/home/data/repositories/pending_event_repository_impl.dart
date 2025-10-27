import '../../domain/entities/pending_event.dart';
import '../../domain/repositories/pending_event_repository.dart';
import '../data_sources/pending_event_remote_data_source.dart';

class PendingEventRepositoryImpl implements PendingEventRepository {
  final PendingEventRemoteDataSource remote;
  
  PendingEventRepositoryImpl(this.remote);

  @override
  Future<List<PendingEvent>> getPendingEvents(String userId) async {
    // ✅ Data source já retorna entities
    return await remote.fetchPending(userId);
  }

  @override
  Future<bool> voteOnEvent(String eventId, String userId, bool isYes) async {
    return await remote.vote(eventId, userId, isYes);
  }
}