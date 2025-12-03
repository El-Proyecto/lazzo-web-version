import '../entities/event.dart';
import '../entities/event_history.dart';

/// Repository interface for event operations
/// Pure Dart interface - no Flutter/Supabase dependencies
abstract class EventRepository {
  /// Create a new event
  Future<Event> createEvent(Event event);

  /// Get event by ID
  Future<Event?> getEventById(String id);

  /// Update an existing event
  Future<Event> updateEvent(Event event);

  /// Delete an event
  Future<void> deleteEvent(String id);

  /// Get events for a group
  Future<List<Event>> getEventsForGroup(String groupId);

  /// Search for location suggestions
  Future<List<EventLocation>> searchLocations(String query);

  /// Get current device location
  Future<EventLocation?> getCurrentLocation();

  /// Get user's recent events for template reuse
  /// Returns events ordered by start_datetime DESC
  /// Independent of group (shows all user's events)
  Future<List<EventHistory>> getUserEventHistory({
    required String userId,
    int limit = 10,
  });
}
