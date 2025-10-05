import '../../domain/entities/poll.dart';
import '../../domain/repositories/poll_repository.dart';

/// Fake poll repository for development
class FakePollRepository implements PollRepository {
  final List<Poll> _polls = [];

  @override
  Future<List<Poll>> getEventPolls(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _polls.where((p) => p.eventId == eventId).toList();
  }

  @override
  Future<Poll> createPoll({
    required String eventId,
    required PollType type,
    required String question,
    required List<String> options,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final poll = Poll(
      id: 'poll-${_polls.length + 1}',
      eventId: eventId,
      type: type,
      question: question,
      options: options
          .asMap()
          .entries
          .map(
            (entry) => PollOption(
              id: 'option-${entry.key}',
              pollId: 'poll-${_polls.length + 1}',
              value: entry.value,
              voteCount: 0,
              votedUserIds: [],
            ),
          )
          .toList(),
      createdAt: DateTime.now(),
      createdBy: 'current-user',
    );

    _polls.add(poll);
    return poll;
  }

  @override
  Future<void> voteOnPoll(String pollId, String optionId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final pollIndex = _polls.indexWhere((p) => p.id == pollId);
    if (pollIndex >= 0) {
      final poll = _polls[pollIndex];
      final updatedOptions = poll.options.map((option) {
        if (option.id == optionId) {
          return option.copyWith(
            voteCount: option.voteCount + 1,
            votedUserIds: [...option.votedUserIds, userId],
          );
        }
        return option;
      }).toList();

      _polls[pollIndex] = poll.copyWith(options: updatedOptions);
    }
  }

  @override
  Future<void> pickFinalOption(String pollId, String optionId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // In real implementation, this would update the event with the selected option
  }
}
