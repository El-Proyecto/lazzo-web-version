import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/suggestion.dart';
import 'package:lazzo/features/event/domain/repositories/suggestion_repository.dart';
import 'package:lazzo/features/event/domain/usecases/create_suggestion.dart';
import 'package:mocktail/mocktail.dart';

class MockSuggestionRepository extends Mock implements SuggestionRepository {}

void main() {
  late MockSuggestionRepository mockRepository;
  late CreateSuggestion sut;

  setUp(() {
    mockRepository = MockSuggestionRepository();
    sut = CreateSuggestion(mockRepository);
  });

  group('CreateSuggestion', () {
    test('calls repository and returns suggestion', () async {
      // Arrange
      final expected = Suggestion(
        id: 's-1',
        eventId: 'event-1',
        userId: 'user-1',
        userName: 'Alice',
        startDateTime: DateTime(2026, 1, 1),
        endDateTime: DateTime(2026, 1, 1, 12),
        createdAt: DateTime(2026, 1, 1),
      );
      when(
        () => mockRepository.createSuggestion(
          eventId: 'event-1',
          userId: 'user-1',
          startDateTime: any(named: 'startDateTime'),
          endDateTime: any(named: 'endDateTime'),
          currentEventStartDateTime: any(named: 'currentEventStartDateTime'),
          currentEventEndDateTime: any(named: 'currentEventEndDateTime'),
        ),
      ).thenAnswer((_) async => expected);

      // Act
      final result = await sut.call(
        eventId: 'event-1',
        userId: 'user-1',
        startDateTime: DateTime(2026, 1, 1),
        endDateTime: DateTime(2026, 1, 1, 12),
      );

      // Assert
      expect(result, expected);
      verify(
        () => mockRepository.createSuggestion(
          eventId: 'event-1',
          userId: 'user-1',
          startDateTime: any(named: 'startDateTime'),
          endDateTime: any(named: 'endDateTime'),
          currentEventStartDateTime: any(named: 'currentEventStartDateTime'),
          currentEventEndDateTime: any(named: 'currentEventEndDateTime'),
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(
        () => mockRepository.createSuggestion(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
          startDateTime: any(named: 'startDateTime'),
          endDateTime: any(named: 'endDateTime'),
          currentEventStartDateTime: any(named: 'currentEventStartDateTime'),
          currentEventEndDateTime: any(named: 'currentEventEndDateTime'),
        ),
      ).thenThrow(Exception('network'));

      // Act & Assert
      expect(
        () => sut.call(
          eventId: 'event-1',
          userId: 'user-1',
          startDateTime: DateTime(2026, 1, 1),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
