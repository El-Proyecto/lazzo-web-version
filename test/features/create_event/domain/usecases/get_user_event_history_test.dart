import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/domain/entities/event_history.dart';
import 'package:lazzo/features/create_event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/create_event/domain/usecases/get_user_event_history.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late GetUserEventHistory sut;

  setUp(() {
    mockRepository = MockEventRepository();
    sut = GetUserEventHistory(mockRepository);
  });

  group('GetUserEventHistory', () {
    test('delegates call and returns history list', () async {
      // Arrange
      final expected = [
        EventHistory(
          id: '1',
          name: 'Event',
          emoji: '🎉',
          startDateTime: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
        ),
      ];
      when(
        () => mockRepository.getUserEventHistory(userId: 'user-1', limit: 10),
      ).thenAnswer((_) async => expected);

      // Act
      final result = await sut.call(userId: 'user-1');

      // Assert
      expect(result, expected);
      verify(
        () => mockRepository.getUserEventHistory(userId: 'user-1', limit: 10),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(
        () => mockRepository.getUserEventHistory(userId: any(named: 'userId'), limit: any(named: 'limit')),
      ).thenThrow(Exception('db'));

      // Act & Assert
      expect(() => sut.call(userId: 'user-1', limit: 5), throwsA(isA<Exception>()));
    });
  });
}
