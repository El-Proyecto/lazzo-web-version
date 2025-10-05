import '../entities/rsvp.dart';

/// RSVP repository interface
/// Defines the contract for RSVP data operations
abstract class RsvpRepository {
  /// Get all RSVPs for an event
  Future<List<Rsvp>> getEventRsvps(String eventId);

  /// Get user's RSVP for an event
  Future<Rsvp?> getUserRsvp(String eventId, String userId);

  /// Create or update RSVP
  Future<Rsvp> submitRsvp(String eventId, String userId, RsvpStatus status);

  /// Get RSVPs by status
  Future<List<Rsvp>> getRsvpsByStatus(String eventId, RsvpStatus status);
}
