import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/domain/entities/event_history.dart';
import 'package:lazzo/features/create_event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/create_event/presentation/providers/event_history_provider.dart';
import 'package:lazzo/features/create_event/presentation/providers/event_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockEventRepository;

  setUp(() {
    mockEventRepository = MockEventRepository();
  });

  group('eventHistoryProvider', () {
    test('returns event history list on success', () async {
      final history = [
        EventHistory(
          id: 'event-1',
          name: 'BBQ',
          emoji: 'X',
          startDateTime: DateTime(2025, 1, 1),
          createdAt: DateTime(2025, 1, 1),
        ),
      ];
      when(() => mockEventRepository.getUserEventHistory(
            userId: 'user-1',
            limit: 10,
          )).thenAnswer((_) async => history);

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(eventHistoryProvider('user-1').future);

      expect(result, history);
      verify(() => mockEventRepository.getUserEventHistory(
            userId: 'user-1',
            limit: 10,
          )).called(1);
      verifyNoMoreInteractions(mockEventRepository);
    });

    test('returns empty list when repository returns empty', () async {
      when(() => mockEventRepository.getUserEventHistory(
            userId: 'user-1',
            limit: 10,
          )).thenAnswer((_) async => <EventHistory>[]);

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(eventHistoryProvider('user-1').future);

      expect(result, isEmpty);
    });
  });
}
