import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/suggestion.dart';
import 'package:lazzo/features/event/domain/repositories/suggestion_repository.dart';
import 'package:lazzo/features/event/domain/usecases/create_location_suggestion.dart';
import 'package:mocktail/mocktail.dart';

class MockSuggestionRepository extends Mock implements SuggestionRepository {}

void main() {
  late MockSuggestionRepository mockRepository;
  late CreateLocationSuggestion sut;

  setUp(() {
    mockRepository = MockSuggestionRepository();
    sut = CreateLocationSuggestion(mockRepository);
  });

  group('CreateLocationSuggestion', () {
    test('calls repository and returns location suggestion', () async {
      // Arrange
      final expected = LocationSuggestion(
        id: 'ls-1',
        eventId: 'event-1',
        userId: 'user-1',
        userName: 'Alice',
        locationName: 'Cafe',
        address: 'Street',
        latitude: 1,
        longitude: 2,
        createdAt: DateTime(2026, 1, 1),
      );
      when(
        () => mockRepository.createLocationSuggestion(
          eventId: 'event-1',
          userId: 'user-1',
          locationName: 'Cafe',
          address: 'Street',
          latitude: 1,
          longitude: 2,
          currentEventLocationName: any(named: 'currentEventLocationName'),
          currentEventAddress: any(named: 'currentEventAddress'),
        ),
      ).thenAnswer((_) async => expected);

      // Act
      final result = await sut.call(
        eventId: 'event-1',
        userId: 'user-1',
        locationName: 'Cafe',
        address: 'Street',
        latitude: 1,
        longitude: 2,
      );

      // Assert
      expect(result, expected);
      verify(
        () => mockRepository.createLocationSuggestion(
          eventId: 'event-1',
          userId: 'user-1',
          locationName: 'Cafe',
          address: 'Street',
          latitude: 1,
          longitude: 2,
          currentEventLocationName: any(named: 'currentEventLocationName'),
          currentEventAddress: any(named: 'currentEventAddress'),
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(
        () => mockRepository.createLocationSuggestion(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
          locationName: any(named: 'locationName'),
          address: any(named: 'address'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          currentEventLocationName: any(named: 'currentEventLocationName'),
          currentEventAddress: any(named: 'currentEventAddress'),
        ),
      ).thenThrow(Exception('network'));

      // Act & Assert
      expect(
        () => sut.call(
          eventId: 'event-1',
          userId: 'user-1',
          locationName: 'Cafe',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
