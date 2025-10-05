import '../entities/event_detail.dart';
import '../repositories/event_repository.dart';

/// Use case to get event details
class GetEventDetail {
  final EventRepository repository;

  const GetEventDetail(this.repository);

  Future<EventDetail> call(String eventId) async {
    return await repository.getEventDetail(eventId);
  }
}
