import '../entities/poll.dart';

/// Poll repository interface
/// Defines the contract for poll data operations
abstract class PollRepository {
  /// Get all polls for an event
  Future<List<Poll>> getEventPolls(String eventId);

  /// Create a new poll suggestion
  Future<Poll> createPoll({
    required String eventId,
    required PollType type,
    required String question,
    required List<String> options,
  });

  /// Vote on a poll option
  Future<void> voteOnPoll(String pollId, String optionId, String userId);

  /// Pick final option (host only)
  Future<void> pickFinalOption(String pollId, String optionId);
}
