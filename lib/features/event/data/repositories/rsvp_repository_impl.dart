import '../../domain/entities/rsvp.dart';
import '../../domain/repositories/rsvp_repository.dart';
import '../data_sources/rsvp_remote_data_source.dart';

/// Implementation of RsvpRepository using Supabase
class RsvpRepositoryImpl implements RsvpRepository {
  final RsvpRemoteDataSource _remoteDataSource;

  RsvpRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Rsvp>> getEventRsvps(String eventId) async {
    final models = await _remoteDataSource.getEventRsvps(eventId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Rsvp?> getUserRsvp(String eventId, String userId) async {
    print('🔍 DEBUG RsvpRepository: Getting user RSVP for eventId=$eventId, userId=$userId');
    final model = await _remoteDataSource.getUserRsvp(eventId, userId);
    print('✅ DEBUG RsvpRepository: Got RSVP model with status=${model?.status}');
    final entity = model?.toEntity();
    print('✅ DEBUG RsvpRepository: Converted to entity with status=${entity?.status}');
    return entity;
  }

  @override
  Future<Rsvp> submitRsvp(
    String eventId,
    String userId,
    RsvpStatus status,
  ) async {
    print('📝 DEBUG RsvpRepository: Submitting RSVP for eventId=$eventId, userId=$userId, status=$status');
    // Convert enum to string (rsvp_status: pending, yes, no, maybe)
    String statusString;
    switch (status) {
      case RsvpStatus.going:
        statusString = 'yes';
        break;
      case RsvpStatus.notGoing:
        statusString = 'no';
        break;
      case RsvpStatus.pending:
        statusString = 'pending';
        break;
    }

    print('📝 DEBUG RsvpRepository: Converted status to string: $statusString');
    final model = await _remoteDataSource.submitRsvp(
      eventId,
      userId,
      statusString,
    );
    print('✅ DEBUG RsvpRepository: Got response model with status=${model.status}');
    final entity = model.toEntity();
    print('✅ DEBUG RsvpRepository: Converted to entity with status=${entity.status}');
    return entity;
  }

  @override
  Future<List<Rsvp>> getRsvpsByStatus(
    String eventId,
    RsvpStatus status,
  ) async {
    // Convert enum to string (rsvp_status: pending, yes, no, maybe)
    String statusString;
    switch (status) {
      case RsvpStatus.going:
        statusString = 'yes';
        break;
      case RsvpStatus.notGoing:
        statusString = 'no';
        break;
      case RsvpStatus.pending:
        statusString = 'pending';
        break;
    }

    final models = await _remoteDataSource.getRsvpsByStatus(
      eventId,
      statusString,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> resetRsvpVotesFromSuggestion(
    String eventId,
    List<String> suggestionVoterUserIds,
  ) async {
    await _remoteDataSource.resetRsvpVotesFromSuggestion(
      eventId,
      suggestionVoterUserIds,
    );
  }
}
