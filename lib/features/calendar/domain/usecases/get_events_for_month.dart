import '../entities/calendar_event_entity.dart';
import '../repositories/calendar_repository.dart';

/// Use case to get events for a specific month
class GetEventsForMonth {
  final CalendarRepository _repository;

  GetEventsForMonth(this._repository);

  Future<List<CalendarEventEntity>> call(int year, int month) {
    return _repository.getEventsForMonth(year, month);
  }
}
