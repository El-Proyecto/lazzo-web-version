import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/data/fakes/fake_poll_repository.dart';
import 'package:lazzo/features/event/domain/entities/poll.dart';
import 'package:lazzo/features/event/domain/repositories/poll_repository.dart';

void main() {
  // ignore: unused_local_variable
  final PollRepository _ = FakePollRepository();

  late FakePollRepository repo;
  late Poll seededPoll;

  setUp(() async {
    repo = FakePollRepository();
    seededPoll = await repo.createPoll(
      eventId: 'event-1',
      type: PollType.date,
      question: 'Qual data?',
      options: const ['Sexta', 'Sabado'],
    );
  });

  group('FakePollRepository', () {
    test('getEventPolls returns non-empty polls for event-1', () async {
      final polls = await repo.getEventPolls('event-1');

      expect(polls, isNotEmpty);
      expect(polls.every((p) => p.eventId == 'event-1'), isTrue);
    });

    test('voteOnPoll increases voteCount for selected option', () async {
      final optionId = seededPoll.options.first.id;

      await repo.voteOnPoll(seededPoll.id, optionId, 'user-1');
      final polls = await repo.getEventPolls('event-1');
      final updated = polls.firstWhere((p) => p.id == seededPoll.id);
      final option = updated.options.firstWhere((o) => o.id == optionId);

      expect(option.voteCount, 1);
    });

    test('double voting by same user is allowed and increments twice', () async {
      final optionId = seededPoll.options.first.id;

      await repo.voteOnPoll(seededPoll.id, optionId, 'same-user');
      await repo.voteOnPoll(seededPoll.id, optionId, 'same-user');

      final polls = await repo.getEventPolls('event-1');
      final updated = polls.firstWhere((p) => p.id == seededPoll.id);
      final option = updated.options.firstWhere((o) => o.id == optionId);

      expect(option.voteCount, 2);
      expect(
        option.votedUserIds.where((id) => id == 'same-user').length,
        2,
      );
    });
  });
}
