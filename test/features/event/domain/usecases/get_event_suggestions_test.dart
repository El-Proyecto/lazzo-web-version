import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/suggestion.dart';
import 'package:lazzo/features/event/domain/repositories/suggestion_repository.dart';
import 'package:lazzo/features/event/domain/usecases/get_event_suggestions.dart';
import 'package:mocktail/mocktail.dart';

class MockSuggestionRepository extends Mock implements SuggestionRepository {}

void main() {
  late MockSuggestionRepository mockRepository;
  late GetEventSuggestions sut;

  setUp(() {
    mockRepository = MockSuggestionRepository();
    sut = GetEventSuggestions(mockRepository);
  });

  group('GetEventSuggestions', () {
    test('calls repository and returns suggestions', () async {
      // Arrange
      final expected = [
        Suggestion(
          id: 's-1',
          eventId: 'event-1',
          userId: 'user-1',
          userName: 'Alice',
          startDateTime: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
        ),
      ];
      when(() => mockRepository.getEventSuggestions('event-1'))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call('event-1');

      // Assert
      expect(result, expected);
      verify(() => mockRepository.getEventSuggestions('event-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.getEventSuggestions(any()))
          .thenThrow(Exception('network'));

      // Act & Assert
      expect(() => sut.call('event-1'), throwsA(isA<Exception>()));
    });
  });
}
