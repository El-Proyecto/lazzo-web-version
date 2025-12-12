import '../entities/event_detail.dart';
import '../repositories/event_repository.dart';

/// Use case to end event immediately
class EndEventNow {
  final EventRepository _repository;

  const EndEventNow(this._repository);

  Future<EventDetail> call(String eventId) async {
    return await _repository.endEventNow(eventId);
  }
}
