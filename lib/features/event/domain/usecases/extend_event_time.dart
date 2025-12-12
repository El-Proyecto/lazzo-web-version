import '../entities/event_detail.dart';
import '../repositories/event_repository.dart';

/// Use case to extend event end time
class ExtendEventTime {
  final EventRepository _repository;

  const ExtendEventTime(this._repository);

  Future<EventDetail> call(String eventId, int minutes) async {
    return await _repository.extendEventTime(eventId, minutes);
  }
}
