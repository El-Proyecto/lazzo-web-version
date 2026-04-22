import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/rsvp.dart';
import 'package:lazzo/features/event/domain/repositories/rsvp_repository.dart';
import 'package:lazzo/features/event/domain/usecases/submit_rsvp.dart';
import 'package:mocktail/mocktail.dart';

class MockRsvpRepository extends Mock implements RsvpRepository {}

void main() {
  late MockRsvpRepository mockRepository;
  late SubmitRsvp sut;

  setUpAll(() {
    registerFallbackValue(RsvpStatus.pending);
  });

  setUp(() {
    mockRepository = MockRsvpRepository();
    sut = SubmitRsvp(mockRepository);
  });

  group('SubmitRsvp', () {
    test('calls repository and returns rsvp', () async {
      // Arrange
      final expected = Rsvp(
        id: 'r-1',
        eventId: 'event-1',
        userId: 'user-1',
        userName: 'Alice',
        status: RsvpStatus.going,
        createdAt: DateTime(2026, 1, 1),
      );
      when(() => mockRepository.submitRsvp('event-1', 'user-1', RsvpStatus.going))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call('event-1', 'user-1', RsvpStatus.going);

      // Assert
      expect(result, expected);
      verify(() => mockRepository.submitRsvp('event-1', 'user-1', RsvpStatus.going))
          .called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.submitRsvp(any(), any(), any()))
          .thenThrow(Exception('network'));

      // Act & Assert
      expect(
        () => sut.call('event-1', 'user-1', RsvpStatus.going),
        throwsA(isA<Exception>()),
      );
    });
  });
}
