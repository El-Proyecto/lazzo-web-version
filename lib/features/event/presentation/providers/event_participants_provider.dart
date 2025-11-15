import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/event_participant_entity.dart';
import '../../domain/usecases/get_event_participants.dart';
import 'event_providers.dart';

final getEventParticipantsUseCaseProvider = Provider<GetEventParticipants>((ref) {
  return GetEventParticipants(ref.watch(eventRepositoryProvider));
});

final eventParticipantsProvider = StateNotifierProvider.family<
    EventParticipantsController, AsyncValue<List<EventParticipantEntity>>, String>((
  ref,
  eventId,
) {
  return EventParticipantsController(
    ref.watch(getEventParticipantsUseCaseProvider),
    eventId,
  );
});

class EventParticipantsController
    extends StateNotifier<AsyncValue<List<EventParticipantEntity>>> {
  final GetEventParticipants _getEventParticipants;
  final String _eventId;

  EventParticipantsController(this._getEventParticipants, this._eventId)
      : super(const AsyncValue.loading()) {
    loadParticipants();
  }

  Future<void> loadParticipants() async {
    state = const AsyncValue.loading();
    try {
      final participants = await _getEventParticipants(_eventId);
      state = AsyncValue.data(participants);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadParticipants();
  }
}