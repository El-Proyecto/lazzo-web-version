import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/rsvp.dart';
import 'package:lazzo/features/event/domain/repositories/rsvp_repository.dart';
import 'package:lazzo/features/event/domain/usecases/get_event_rsvps.dart';
import 'package:mocktail/mocktail.dart';

class MockRsvpRepository extends Mock implements RsvpRepository {}

void main() {
  late MockRsvpRepository mockRepository;
  late GetEventRsvps sut;

  setUp(() {
    mockRepository = MockRsvpRepository();
    sut = GetEventRsvps(mockRepository);
  });

  group('GetEventRsvps', () {
    test('calls repository and returns RSVPs', () async {
      // Arrange
      final expected = [
        Rsvp(
          id: 'r-1',
          eventId: 'event-1',
          userId: 'user-1',
          userName: 'Alice',
          status: RsvpStatus.going,
          createdAt: DateTime(2026, 1, 1),
        ),
      ];
      when(() => mockRepository.getEventRsvps('event-1'))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call('event-1');

      // Assert
      expect(result, expected);
      verify(() => mockRepository.getEventRsvps('event-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.getEventRsvps(any()))
          .thenThrow(Exception('network'));

      // Act & Assert
      expect(() => sut.call('event-1'), throwsA(isA<Exception>()));
    });
  });
}
