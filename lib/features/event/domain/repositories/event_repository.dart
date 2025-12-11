import '../entities/event_detail.dart';
import '../entities/event_participant_entity.dart';

/// Event repository interface
/// Defines the contract for event data operations
abstract class EventRepository {
  /// Get event details by ID
  Future<EventDetail> getEventDetail(String eventId);

  /// Check if user is the event host
  Future<bool> isUserHost(String eventId, String userId);

  /// Update event date/time
  Future<EventDetail> updateEventDateTime(
    String eventId,
    DateTime startDateTime,
    DateTime? endDateTime,
  );

  /// Update event location
  Future<EventDetail> updateEventLocation(
    String eventId,
    String locationName,
    String address,
    double latitude,
    double longitude,
  );

  /// Update event status
  Future<EventDetail> updateEventStatus(
    String eventId,
    EventStatus status,
  );

  Future<List<EventParticipantEntity>> getEventParticipants(String eventId);

  /// Extend event end time by specified minutes
  Future<EventDetail> extendEventTime(
    String eventId,
    int minutes,
  );

  /// End event immediately (set end time to now)
  Future<EventDetail> endEventNow(String eventId);
}
