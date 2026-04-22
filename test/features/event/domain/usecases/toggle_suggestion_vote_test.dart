import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/suggestion.dart';
import 'package:lazzo/features/event/domain/repositories/suggestion_repository.dart';
import 'package:lazzo/features/event/domain/usecases/toggle_suggestion_vote.dart';
import 'package:mocktail/mocktail.dart';

class MockSuggestionRepository extends Mock implements SuggestionRepository {}

void main() {
  late MockSuggestionRepository mockRepository;
  late ToggleSuggestionVote sut;

  setUp(() {
    mockRepository = MockSuggestionRepository();
    sut = ToggleSuggestionVote(mockRepository);
  });

  group('ToggleSuggestionVote', () {
    test('when user has not voted, votes and returns true', () async {
      // Arrange
      when(
        () => mockRepository.getUserSuggestionVotes(
          eventId: 'event-1',
          userId: 'user-1',
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockRepository.voteOnSuggestion(
          suggestionId: 's-1',
          userId: 'user-1',
          eventId: 'event-1',
        ),
      ).thenAnswer(
        (_) async => SuggestionVote(
          id: 'v-1',
          suggestionId: 's-1',
          userId: 'user-1',
          userName: 'Alice',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      // Act
      final result = await sut.call(
        suggestionId: 's-1',
        userId: 'user-1',
        eventId: 'event-1',
      );

      // Assert
      expect(result, isTrue);
      verify(
        () => mockRepository.getUserSuggestionVotes(
          eventId: 'event-1',
          userId: 'user-1',
        ),
      ).called(1);
      verify(
        () => mockRepository.voteOnSuggestion(
          suggestionId: 's-1',
          userId: 'user-1',
          eventId: 'event-1',
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('when user has voted, removes vote and returns false', () async {
      // Arrange
      when(
        () => mockRepository.getUserSuggestionVotes(
          eventId: 'event-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async => [
          SuggestionVote(
            id: 'v-1',
            suggestionId: 's-1',
            userId: 'user-1',
            userName: 'Alice',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      when(
        () => mockRepository.removeVoteFromSuggestion(
          suggestionId: 's-1',
          userId: 'user-1',
        ),
      ).thenAnswer((_) async {});

      // Act
      final result = await sut.call(
        suggestionId: 's-1',
        userId: 'user-1',
        eventId: 'event-1',
      );

      // Assert
      expect(result, isFalse);
      verify(
        () => mockRepository.getUserSuggestionVotes(
          eventId: 'event-1',
          userId: 'user-1',
        ),
      ).called(1);
      verify(
        () => mockRepository.removeVoteFromSuggestion(
          suggestionId: 's-1',
          userId: 'user-1',
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
