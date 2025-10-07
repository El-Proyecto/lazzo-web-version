import '../repositories/suggestion_repository.dart';

/// Use case to toggle vote on a suggestion
class ToggleSuggestionVote {
  final SuggestionRepository repository;

  const ToggleSuggestionVote(this.repository);

  Future<bool> call({
    required String suggestionId,
    required String userId,
    required String eventId,
  }) async {
    // Get user's current votes to check if they already voted
    final userVotes = await repository.getUserSuggestionVotes(
      eventId: eventId,
      userId: userId,
    );

    final hasVoted = userVotes.any((vote) => vote.suggestionId == suggestionId);

    if (hasVoted) {
      // Remove vote
      await repository.removeVoteFromSuggestion(
        suggestionId: suggestionId,
        userId: userId,
      );
      return false; // Vote removed
    } else {
      // Add vote
      await repository.voteOnSuggestion(
        suggestionId: suggestionId,
        userId: userId,
      );
      return true; // Vote added
    }
  }
}
