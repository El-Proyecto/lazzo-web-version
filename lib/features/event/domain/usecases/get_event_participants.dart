import '../entities/event_participant_entity.dart';
import '../repositories/event_repository.dart';

class GetEventParticipants {
  final EventRepository _repository;

  GetEventParticipants(this._repository);

  Future<List<EventParticipantEntity>> call(String eventId) async {
    return await _repository.getEventParticipants(eventId);
  }
}