import '../../domain/entities/suggestion.dart';
import '../../domain/repositories/suggestion_repository.dart';
import '../data_sources/suggestion_remote_data_source.dart';

/// Implementation of SuggestionRepository using Supabase
class SuggestionRepositoryImpl implements SuggestionRepository {
  final SuggestionRemoteDataSource _remoteDataSource;

  SuggestionRepositoryImpl(this._remoteDataSource);

  // ============================================================================
  // DATETIME SUGGESTIONS
  // ============================================================================

  @override
  Future<List<Suggestion>> getEventSuggestions(String eventId) async {
    final models = await _remoteDataSource.getEventSuggestions(eventId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Suggestion> createSuggestion({
    required String eventId,
    required String userId,
    required DateTime startDateTime,
    DateTime? endDateTime,
    DateTime? currentEventStartDateTime,
    DateTime? currentEventEndDateTime,
  }) async {
    final model = await _remoteDataSource.createSuggestion(
      eventId: eventId,
      userId: userId,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      currentEventStartDateTime: currentEventStartDateTime,
      currentEventEndDateTime: currentEventEndDateTime,
    );
    return model.toEntity();
  }

  @override
  Future<List<SuggestionVote>> getEventSuggestionVotes(String eventId) async {
    final models = await _remoteDataSource.getEventSuggestionVotes(eventId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<SuggestionVote> voteOnSuggestion({
    required String suggestionId,
    required String userId,
    required String eventId,
  }) async {
    final model = await _remoteDataSource.voteOnSuggestion(
      suggestionId: suggestionId,
      userId: userId,
      eventId: eventId,
    );
    return model.toEntity();
  }

  @override
  Future<void> removeVoteFromSuggestion({
    required String suggestionId,
    required String userId,
  }) async {
    await _remoteDataSource.removeVoteFromSuggestion(
      suggestionId: suggestionId,
      userId: userId,
    );
  }

  @override
  Future<List<SuggestionVote>> getUserSuggestionVotes({
    required String eventId,
    required String userId,
  }) async {
    final models = await _remoteDataSource.getUserSuggestionVotes(
      eventId: eventId,
      userId: userId,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> clearEventSuggestions(String eventId) async {
    await _remoteDataSource.clearEventSuggestions(eventId);
  }

  // ============================================================================
  // LOCATION SUGGESTIONS
  // ============================================================================

  @override
  Future<List<LocationSuggestion>> getEventLocationSuggestions(
    String eventId,
  ) async {
    final models = await _remoteDataSource.getEventLocationSuggestions(eventId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<LocationSuggestion> createLocationSuggestion({
    required String eventId,
    required String userId,
    required String locationName,
    String? address,
    double? latitude,
    double? longitude,
    String? currentEventLocationName,
    String? currentEventAddress,
  }) async {
    final model = await _remoteDataSource.createLocationSuggestion(
      eventId: eventId,
      userId: userId,
      locationName: locationName,
      address: address,
      latitude: latitude,
      longitude: longitude,
      currentEventLocationName: currentEventLocationName,
      currentEventAddress: currentEventAddress,
    );
    return model.toEntity();
  }

  @override
  Future<List<SuggestionVote>> getEventLocationSuggestionVotes(
    String eventId,
  ) async {
    final models =
        await _remoteDataSource.getEventLocationSuggestionVotes(eventId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<SuggestionVote> voteOnLocationSuggestion({
    required String suggestionId,
    required String userId,
  }) async {
    final model = await _remoteDataSource.voteOnLocationSuggestion(
      suggestionId: suggestionId,
      userId: userId,
    );
    return model.toEntity();
  }

  @override
  Future<void> removeVoteFromLocationSuggestion({
    required String suggestionId,
    required String userId,
  }) async {
    await _remoteDataSource.removeVoteFromLocationSuggestion(
      suggestionId: suggestionId,
      userId: userId,
    );
  }

  @override
  Future<List<SuggestionVote>> getUserLocationSuggestionVotes({
    required String eventId,
    required String userId,
  }) async {
    final models = await _remoteDataSource.getUserLocationSuggestionVotes(
      eventId: eventId,
      userId: userId,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> clearEventLocationSuggestions(String eventId) async {
    await _remoteDataSource.clearEventLocationSuggestions(eventId);
  }

  @override
  Future<LocationSuggestion> createCurrentLocationSuggestion({
    required String eventId,
    required String userId,
    required String locationName,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final model = await _remoteDataSource.createCurrentLocationSuggestion(
      eventId: eventId,
      userId: userId,
      locationName: locationName,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
    return model.toEntity();
  }
}
