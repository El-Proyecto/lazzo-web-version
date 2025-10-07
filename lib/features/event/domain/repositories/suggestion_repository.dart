import '../entities/suggestion.dart';

/// Repository interface for suggestion operations
abstract class SuggestionRepository {
  /// Get all suggestions for an event
  Future<List<Suggestion>> getEventSuggestions(String eventId);

  /// Create a new suggestion
  Future<Suggestion> createSuggestion({
    required String eventId,
    required String userId,
    required DateTime startDateTime,
    DateTime? endDateTime,
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
}
