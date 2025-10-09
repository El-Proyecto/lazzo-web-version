import '../../domain/entities/suggestion.dart';
import '../../domain/repositories/suggestion_repository.dart';
import 'fake_rsvp_repository.dart';

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
    DateTime? currentEventStartDateTime,
    DateTime? currentEventEndDateTime,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if this is the first suggestion for this event
    final existingSuggestions = _suggestions[eventId] ?? [];
    final isFirstSuggestion = existingSuggestions.isEmpty;

    // Create the new suggestion
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

    // If this is the first suggestion and we have current event dates,
    // create a "current" suggestion first
    final allSuggestions = <Suggestion>[...existingSuggestions];

    if (isFirstSuggestion && currentEventStartDateTime != null) {
      final currentDateSuggestion = Suggestion(
        id: 'current_event_suggestion_${++_suggestionIdCounter}',
        eventId: eventId,
        userId: 'system', // System-generated suggestion
        userName: 'Event Date',
        userAvatar: null,
        startDateTime: currentEventStartDateTime,
        endDateTime: currentEventEndDateTime,
        createdAt: DateTime.now().subtract(
          const Duration(seconds: 1),
        ), // Make it appear first chronologically
      );
      allSuggestions.add(currentDateSuggestion);

      // Auto-vote all users with RSVP "going" status on the current suggestion
      await _autoVoteFromRsvps(eventId, currentDateSuggestion.id);
    }

    // Add the new user suggestion
    allSuggestions.add(suggestion);

    _suggestions[eventId] = allSuggestions;

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
  } // Helper methods to generate fake user data

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

  /// Auto-vote users with RSVP "going" status on a suggestion
  Future<void> _autoVoteFromRsvps(String eventId, String suggestionId) async {
    try {
      // Get the fake RSVP repository instance
      final rsvpRepository = FakeRsvpRepository();
      final rsvps = await rsvpRepository.getEventRsvps(eventId);

      // Find all users with "going" status
      final goingUsers = rsvps
          .where((rsvp) => rsvp.status.name == 'going')
          .toList();

      // Auto-vote each "going" user on the current suggestion
      for (final rsvp in goingUsers) {
        final vote = SuggestionVote(
          id: 'auto_vote_${++_voteIdCounter}',
          suggestionId: suggestionId,
          userId: rsvp.userId,
          userName: rsvp.userName,
          userAvatar: rsvp.userAvatar,
          createdAt: DateTime.now(),
        );

        _votes[suggestionId] = [...(_votes[suggestionId] ?? []), vote];
      }
    } catch (e) {
      // Silently fail if RSVPs can't be accessed
      // This prevents breaking the suggestion creation
    }
  }

  /// Sync current suggestion votes with RSVP status
  /// This method should be called after RSVP data is updated (e.g., after Set Date)
  static Future<void> syncCurrentSuggestionWithRsvp(String eventId) async {
    try {
      // Find the current event suggestion
      final suggestions = _suggestions[eventId] ?? [];
      final currentSuggestion = suggestions.firstWhere(
        (s) =>
            s.userId == 'system' && s.id.contains('current_event_suggestion'),
        orElse: () => throw Exception('No current suggestion found'),
      );

      // Clear existing votes for the current suggestion
      _votes[currentSuggestion.id] = [];

      // Get updated RSVP data
      final rsvpRepository = FakeRsvpRepository();
      final rsvps = await rsvpRepository.getEventRsvps(eventId);

      // Find all users with "going" status
      final goingUsers = rsvps
          .where((rsvp) => rsvp.status.name == 'going')
          .toList();

      // Add votes for each "going" user
      for (final rsvp in goingUsers) {
        final vote = SuggestionVote(
          id: 'sync_vote_${++_voteIdCounter}',
          suggestionId: currentSuggestion.id,
          userId: rsvp.userId,
          userName: rsvp.userName,
          userAvatar: rsvp.userAvatar,
          createdAt: DateTime.now(),
        );

        _votes[currentSuggestion.id] = [
          ...(_votes[currentSuggestion.id] ?? []),
          vote,
        ];
      }
    } catch (e) {
      // Silently fail if current suggestion doesn't exist or can't be synced
      // This prevents breaking other operations
    }
  }

  /// Clear all data (for testing)
  static void clearAll() {
    _suggestions.clear();
    _votes.clear();
    _suggestionIdCounter = 0;
    _voteIdCounter = 0;
  }
}
