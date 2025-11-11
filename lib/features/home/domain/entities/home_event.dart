/// Home event entity for display in home page sections
/// Contains essential info needed for event cards
class HomeEventEntity {
  final String id;
  final String name;
  final String emoji;
  final DateTime? date;
  final String? location;
  final HomeEventStatus status;
  final int goingCount;
  final List<String> attendeeAvatars; // Profile picture URLs
  final List<String> attendeeNames; // Names of attendees

  const HomeEventEntity({
    required this.id,
    required this.name,
    required this.emoji,
    this.date,
    this.location,
    required this.status,
    required this.goingCount,
    required this.attendeeAvatars,
    required this.attendeeNames,
  });
}

/// Status of a home event
/// Pending: waiting for confirmation
/// Confirmed: planning phase confirmed
/// Living: event is happening now
/// Recap: event ended, in recap phase
enum HomeEventStatus { pending, confirmed, living, recap }
