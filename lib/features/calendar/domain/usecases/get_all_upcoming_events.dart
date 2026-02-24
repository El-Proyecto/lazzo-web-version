import '../entities/calendar_event_entity.dart';
import '../repositories/calendar_repository.dart';

/// Use case to get all upcoming events for list view
class GetAllUpcomingEvents {
  final CalendarRepository _repository;

  GetAllUpcomingEvents(this._repository);

  Future<List<CalendarEventEntity>> call() {
    return _repository.getAllUpcomingEvents();
  }
}
