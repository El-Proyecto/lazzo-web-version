import '../entities/event_detail.dart';
import '../repositories/event_repository.dart';

/// Use case to update event status (pending/confirmed)
class UpdateEventStatus {
  final EventRepository _repository;

  UpdateEventStatus(this._repository);

  /// Update the event status
  Future<EventDetail> call(String eventId, EventStatus status) async {
    return await _repository.updateEventStatus(eventId, status);
  }
}
