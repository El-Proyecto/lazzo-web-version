import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/event_participant_entity.dart';
import 'package:lazzo/features/event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/event/presentation/providers/event_providers.dart'
    hide eventParticipantsProvider;
import 'package:lazzo/features/event/presentation/providers/event_participants_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockEventRepository;

  setUp(() {
    mockEventRepository = MockEventRepository();
  });

  group('eventParticipantsProvider', () {
    test('loads participants on refresh success', () async {
      final participants = [
        const EventParticipantEntity(
          userId: 'user-1',
          displayName: 'User One',
          status: 'confirmed',
        ),
      ];
      when(() => mockEventRepository.getEventParticipants('event-1'))
          .thenAnswer((_) async => participants);

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(eventParticipantsProvider('event-1').notifier);
      await notifier.refresh();
      final state = container.read(eventParticipantsProvider('event-1'));

      expect(state.value, participants);
      verify(() => mockEventRepository.getEventParticipants('event-1'))
          .called(greaterThanOrEqualTo(1));
    });

    test('sets error state when use case fails', () async {
      when(() => mockEventRepository.getEventParticipants(any()))
          .thenThrow(Exception('participants-fail'));

      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(eventParticipantsProvider('event-1').notifier);
      await notifier.refresh();
      final state = container.read(eventParticipantsProvider('event-1'));

      expect(state.hasError, isTrue);
    });
  });
}
