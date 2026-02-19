/// Lightweight entity for calendar display
/// Contains only the fields needed for calendar grid and day event list
class CalendarEventEntity {
  final String id;
  final String name;
  final String emoji;
  final DateTime? date;
  final DateTime? endDate;
  final String? location;
  final CalendarEventStatus status;
  final String? groupName;
  final String? coverPhotoUrl; // Memory cover photo for past events

  const CalendarEventEntity({
    required this.id,
    required this.name,
    required this.emoji,
    this.date,
    this.endDate,
    this.location,
    required this.status,
    this.groupName,
    this.coverPhotoUrl,
  });

  /// Whether the event has a memory with photos (past events)
  bool get hasMemory => coverPhotoUrl != null && coverPhotoUrl!.isNotEmpty;

  /// Whether the event is in the past
  bool get isPast {
    if (date == null) return false;
    return DateTime.now().isAfter(date!);
  }
}

/// Status of a calendar event
enum CalendarEventStatus { pending, confirmed, living, recap }
