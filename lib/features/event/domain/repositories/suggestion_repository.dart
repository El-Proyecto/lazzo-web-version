import '../entities/suggestion.dart';

/// Repository interface for suggestion operations
abstract class SuggestionRepository {
  /// Get all suggestions for an event
  Future<List<Suggestion>> getEventSuggestions(String eventId);

  /// Create a new suggestion
  /// Automatically creates a "current" suggestion if this is the first suggestion for the event
  Future<Suggestion> createSuggestion({
    required String eventId,
    required String userId,
    required DateTime startDateTime,
    DateTime? endDateTime,
    DateTime? currentEventStartDateTime,
    DateTime? currentEventEndDateTime,
  });

  /// Get all votes for event suggestions
  Future<List<SuggestionVote>> getEventSuggestionVotes(String eventId);

  /// Vote on a suggestion
  Future<SuggestionVote> voteOnSuggestion({
    required String suggestionId,
    required String userId,
  });

  /// Remove vote from a suggestion
  Future<void> removeVoteFromSuggestion({
    required String suggestionId,
    required String userId,
  });

  /// Get user's votes for event suggestions
  Future<List<SuggestionVote>> getUserSuggestionVotes({
    required String eventId,
    required String userId,
  });

  /// Clear all suggestions and votes for an event
  Future<void> clearEventSuggestions(String eventId);

  // Location suggestion methods

  /// Get all location suggestions for an event
  Future<List<LocationSuggestion>> getEventLocationSuggestions(String eventId);

  /// Create a new location suggestion
  Future<LocationSuggestion> createLocationSuggestion({
    required String eventId,
    required String userId,
    required String locationName,
    String? address,
    double? latitude,
    double? longitude,
    String? currentEventLocationName,
    String? currentEventAddress,
  });

  /// Get all votes for event location suggestions
  Future<List<SuggestionVote>> getEventLocationSuggestionVotes(String eventId);

  /// Vote on a location suggestion
  Future<SuggestionVote> voteOnLocationSuggestion({
    required String suggestionId,
    required String userId,
  });

  /// Remove vote from a location suggestion
  Future<void> removeVoteFromLocationSuggestion({
    required String suggestionId,
    required String userId,
  });

  /// Get user's votes for event location suggestions
  Future<List<SuggestionVote>> getUserLocationSuggestionVotes({
    required String eventId,
    required String userId,
  });

  /// Clear all location suggestions and votes for an event
  Future<void> clearEventLocationSuggestions(String eventId);
}
