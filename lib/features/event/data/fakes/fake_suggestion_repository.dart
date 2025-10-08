import '../../domain/entities/suggestion.dart';
import '../../domain/repositories/suggestion_repository.dart';

/// Fake implementation of SuggestionRepository for development
class FakeSuggestionRepository implements SuggestionRepository {
  static final Map<String, List<Suggestion>> _suggestions = {};
  static final Map<String, List<SuggestionVote>> _votes = {};
  static int _suggestionIdCounter = 0;
  static int _voteIdCounter = 0;

  @override
  Future<List<Suggestion>> getEventSuggestions(String eventId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final suggestions = _suggestions[eventId] ?? [];
    return suggestions;
  }

  @override
  Future<Suggestion> createSuggestion({
    required String eventId,
    required String userId,
    required DateTime startDateTime,
    DateTime? endDateTime,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final suggestion = Suggestion(
      id: 'suggestion_${++_suggestionIdCounter}',
      eventId: eventId,
      userId: userId,
      userName: _getUserName(userId),
      userAvatar: _getUserAvatar(userId),
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      createdAt: DateTime.now(),
    );

    _suggestions[eventId] = [...(_suggestions[eventId] ?? []), suggestion];

    return suggestion;
  }

  @override
  Future<List<SuggestionVote>> getEventSuggestionVotes(String eventId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final eventSuggestions = _suggestions[eventId] ?? [];
    final eventSuggestionIds = eventSuggestions.map((s) => s.id).toSet();

    return _votes.values
        .expand((votes) => votes)
        .where((vote) => eventSuggestionIds.contains(vote.suggestionId))
        .toList();
  }

  @override
  Future<SuggestionVote> voteOnSuggestion({
    required String suggestionId,
    required String userId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final vote = SuggestionVote(
      id: 'vote_${++_voteIdCounter}',
      suggestionId: suggestionId,
      userId: userId,
      userName: _getUserName(userId),
      userAvatar: _getUserAvatar(userId),
      createdAt: DateTime.now(),
    );

    _votes[suggestionId] = [...(_votes[suggestionId] ?? []), vote];

    return vote;
  }

  @override
  Future<void> removeVoteFromSuggestion({
    required String suggestionId,
    required String userId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    _votes[suggestionId]?.removeWhere((vote) => vote.userId == userId);
  }

  @override
  Future<List<SuggestionVote>> getUserSuggestionVotes({
    required String eventId,
    required String userId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final eventSuggestions = _suggestions[eventId] ?? [];
    final eventSuggestionIds = eventSuggestions.map((s) => s.id).toSet();

    return _votes.values
        .expand((votes) => votes)
        .where(
          (vote) =>
              vote.userId == userId &&
              eventSuggestionIds.contains(vote.suggestionId),
        )
        .toList();
  }

  @override
  Future<void> clearEventSuggestions(String eventId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Get all suggestion IDs for this event
    final eventSuggestions = _suggestions[eventId] ?? [];
    final suggestionIds = eventSuggestions.map((s) => s.id).toList();

    // Remove all votes for these suggestions
    for (final suggestionId in suggestionIds) {
      _votes.remove(suggestionId);
    }

    // Remove all suggestions for this event
    _suggestions.remove(eventId);
  }

  // Helper methods to generate fake user data
  String _getUserName(String userId) {
    switch (userId) {
      case 'current-user':
        return 'You';
      case 'user-2':
        return 'Alice Johnson';
      case 'user-3':
        return 'Bob Smith';
      case 'user-4':
        return 'Carol Davis';
      default:
        return 'Unknown User';
    }
  }

  String? _getUserAvatar(String userId) {
    // Return null for fake implementation
    return null;
  }

  /// Clear all data (for testing)
  static void clearAll() {
    _suggestions.clear();
    _votes.clear();
    _suggestionIdCounter = 0;
    _voteIdCounter = 0;
  }
}
