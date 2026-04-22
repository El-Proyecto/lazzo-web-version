import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/poll.dart';

void main() {
  final baseOption = const PollOption(
    id: 'opt-1',
    pollId: 'poll-1',
    value: 'Option A',
    voteCount: 1,
    votedUserIds: ['u-1'],
  );

  final basePoll = Poll(
    id: 'poll-1',
    eventId: 'event-1',
    type: PollType.date,
    question: 'When?',
    options: [baseOption],
    createdAt: DateTime(2025, 7, 10),
    createdBy: 'host-1',
  );

  group('Poll.copyWith', () {
    test('replaces options list', () {
      final newOptions = const [
        PollOption(
          id: 'opt-2',
          pollId: 'poll-1',
          value: 'Option B',
          voteCount: 3,
          votedUserIds: ['u-2', 'u-3'],
        ),
      ];

      final updated = basePoll.copyWith(options: newOptions);

      expect(updated.options, newOptions);
      expect(updated.options.first.id, 'opt-2');
    });
  });

  group('PollOption.copyWith', () {
    test('updates voteCount', () {
      final updated = baseOption.copyWith(voteCount: 10);
      expect(updated.voteCount, 10);
    });

    test('supports empty votedUserIds', () {
      const option = PollOption(
        id: 'opt-empty',
        pollId: 'poll-2',
        value: 'Option C',
        voteCount: 0,
        votedUserIds: [],
      );

      expect(option.votedUserIds, isEmpty);
    });
  });
}
