import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/data/fakes/fake_suggestion_repository.dart';
import 'package:lazzo/features/event/domain/repositories/suggestion_repository.dart';

void main() {
  // ignore: unused_local_variable
  final SuggestionRepository _ = FakeSuggestionRepository();

  late FakeSuggestionRepository repo;

  setUp(() {
    FakeSuggestionRepository.clearAll();
    repo = FakeSuggestionRepository();
  });

  group('FakeSuggestionRepository', () {
    test('getEventSuggestions returns seeded list after creation', () async {
      await repo.createSuggestion(
        eventId: 'event-1',
        userId: 'user-1',
        startDateTime: DateTime.now().add(const Duration(days: 1)),
      );

      final suggestions = await repo.getEventSuggestions('event-1');
      expect(suggestions, isNotEmpty);
      expect(suggestions.every((s) => s.eventId == 'event-1'), isTrue);
    });

    test('createSuggestion returns entity with non-empty id', () async {
      final suggestion = await repo.createSuggestion(
        eventId: 'event-1',
        userId: 'user-2',
        startDateTime: DateTime.now().add(const Duration(days: 2)),
      );

      expect(suggestion.id, isNotEmpty);
      expect(suggestion.userId, 'user-2');
    });

    test('voteOnSuggestion and removeVoteFromSuggestion toggle votes', () async {
      final suggestion = await repo.createSuggestion(
        eventId: 'event-1',
        userId: 'user-1',
        startDateTime: DateTime.now(),
      );

      await repo.voteOnSuggestion(
        suggestionId: suggestion.id,
        userId: 'user-voter',
        eventId: 'event-1',
      );
      var votes = await repo.getUserSuggestionVotes(
        eventId: 'event-1',
        userId: 'user-voter',
      );
      expect(votes, isNotEmpty);

      await repo.removeVoteFromSuggestion(
        suggestionId: suggestion.id,
        userId: 'user-voter',
      );
      votes = await repo.getUserSuggestionVotes(
        eventId: 'event-1',
        userId: 'user-voter',
      );
      expect(votes, isEmpty);
    });

    test('getUserSuggestionVotes returns votes only for requested user',
        () async {
      final suggestion = await repo.createSuggestion(
        eventId: 'event-1',
        userId: 'user-creator',
        startDateTime: DateTime.now(),
      );

      await repo.voteOnSuggestion(
        suggestionId: suggestion.id,
        userId: 'user-a',
        eventId: 'event-1',
      );
      await repo.voteOnSuggestion(
        suggestionId: suggestion.id,
        userId: 'user-b',
        eventId: 'event-1',
      );

      final userAVotes = await repo.getUserSuggestionVotes(
        eventId: 'event-1',
        userId: 'user-a',
      );

      expect(userAVotes, hasLength(1));
      expect(userAVotes.first.userId, 'user-a');
    });
  });
}
