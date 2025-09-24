import '../../domain/entities/pending_event.dart';
import '../../domain/repositories/pending_event_repository.dart';
import '../data_sources/pending_event_remote_data_source.dart';

class PendingEventRepositoryImpl implements PendingEventRepository {
  final PendingEventRemoteDataSource
  remote; // injeta o datasource (ex.: Supabase)
  PendingEventRepositoryImpl(this.remote);

  @override
  Future<List<PendingEvent>> getPendingEvents(String userId) async {
    final list = await remote.fetchPending(userId);
    return list.map((e) => e.toEntity()).toList();
  }

  @override
  Future<bool> voteOnEvent(String eventId, String userId, bool isYes) async {
    return await remote.vote(eventId, userId, isYes);
  }
}
