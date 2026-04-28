import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/suggestion.dart';

void main() {
  group('Suggestion equality', () {
    test('entities with same id are equal', () {
      final first = Suggestion(
        id: 's-1',
        eventId: 'e-1',
        userId: 'u-1',
        userName: 'Ana',
        startDateTime: DateTime(2025, 7, 1, 18),
        createdAt: DateTime(2025, 7, 1),
      );
      final second = Suggestion(
        id: 's-1',
        eventId: 'e-2',
        userId: 'u-2',
        userName: 'Bia',
        startDateTime: DateTime(2025, 7, 2, 18),
        createdAt: DateTime(2025, 7, 2),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });

  group('LocationSuggestion equality', () {
    test('entities with same id are equal', () {
      final first = LocationSuggestion(
        id: 'ls-1',
        eventId: 'e-1',
        userId: 'u-1',
        userName: 'Ana',
        locationName: 'Park',
        createdAt: DateTime(2025, 7, 1),
      );
      final second = LocationSuggestion(
        id: 'ls-1',
        eventId: 'e-2',
        userId: 'u-2',
        userName: 'Bia',
        locationName: 'Beach',
        createdAt: DateTime(2025, 7, 2),
      );

      expect(first, second);
    });
  });

  group('SuggestionVote equality', () {
    test('entities with same id are equal', () {
      final first = SuggestionVote(
        id: 'sv-1',
        suggestionId: 's-1',
        userId: 'u-1',
        userName: 'Ana',
        createdAt: DateTime(2025, 7, 1),
      );
      final second = SuggestionVote(
        id: 'sv-1',
        suggestionId: 's-2',
        userId: 'u-2',
        userName: 'Bia',
        createdAt: DateTime(2025, 7, 2),
      );

      expect(first, second);
    });
  });
}
