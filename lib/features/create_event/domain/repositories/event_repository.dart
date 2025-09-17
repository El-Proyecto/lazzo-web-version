import '../entities/event.dart';

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
}
