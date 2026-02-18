import '../entities/calendar_event_entity.dart';

/// Repository interface for calendar data
abstract class CalendarRepository {
  /// Get all events for a specific month
  Future<List<CalendarEventEntity>> getEventsForMonth(int year, int month);

  /// Get all events (for list view)
  Future<List<CalendarEventEntity>> getAllUpcomingEvents();
}
