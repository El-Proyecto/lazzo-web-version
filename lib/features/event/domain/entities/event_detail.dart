/// Event detail domain entity
/// Extended event information for the event detail page
class EventDetail {
  final String id;
  final String name;
  final String emoji;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final EventLocation? location;
  final EventStatus status;
  final DateTime createdAt;
  final String hostId;
  final int goingCount;
  final int notGoingCount;
  final String? description;

  const EventDetail({
    required this.id,
    required this.name,
    required this.emoji,
    this.startDateTime,
    this.endDateTime,
    this.location,
    required this.status,
    required this.createdAt,
    required this.hostId,
    required this.goingCount,
    required this.notGoingCount,
    this.description,
  });

  EventDetail copyWith({
    String? id,
    String? name,
    String? emoji,
    DateTime? startDateTime,
    DateTime? endDateTime,
    EventLocation? location,
    EventStatus? status,
    DateTime? createdAt,
    String? hostId,
    int? goingCount,
    int? notGoingCount,
    String? description,
    bool clearDescription = false,
  }) {
    return EventDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      hostId: hostId ?? this.hostId,
      goingCount: goingCount ?? this.goingCount,
      notGoingCount: notGoingCount ?? this.notGoingCount,
      description:
          clearDescription ? description : (description ?? this.description),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES FOR PLANNING STATES
  // These properties encapsulate business logic for determining event
  // planning status, following DDD principles. UI code should read these
  // properties instead of checking nullable fields directly.
  // ═════════════════════════════════════════════════════════════════════════

  /// Check if event has both location and date defined
  /// Returns true only when both fields are non-null
  bool get isFullyDefined => location != null && startDateTime != null;

  /// Check if event has location defined
  /// Returns true when location is set, regardless of date
  bool get hasDefinedLocation => location != null;

  /// Check if event has date defined
  /// Returns true when start date is set, regardless of location
  bool get hasDefinedDate => startDateTime != null;

  /// Check if event date has expired
  /// Returns true when event is in pending status and start date has passed
  bool get isExpired {
    final hasStartDate = startDateTime != null;

    if (hasStartDate) {}

    if (status != EventStatus.pending) return false;
    if (startDateTime == null) return false;
    return DateTime.now().isAfter(startDateTime!);
  }

  /// Planning status for conditional UI rendering
  /// Determines which widgets to show (RSVP vs HelpPlan)
  EventPlanningStatus get planningStatus {
    if (isFullyDefined) return EventPlanningStatus.bothDefined;
    if (hasDefinedLocation || hasDefinedDate) {
      return EventPlanningStatus.partialDefined;
    }
    return EventPlanningStatus.noneDefined;
  }
}

/// Event location domain entity
class EventLocation {
  final String id;
  final String displayName;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  const EventLocation({
    required this.id,
    required this.displayName,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });
}

/// Event status enumeration
enum EventStatus { pending, confirmed, living, recap }

/// Event planning status based on location and date definition
/// Used to determine which UI widgets to show (RSVP vs HelpPlan)
enum EventPlanningStatus {
  /// Both location and date are defined - show RSVP widget
  bothDefined,

  /// Only one of location or date is defined - show HelpPlan widget
  partialDefined,

  /// Neither location nor date is defined - show HelpPlan widget
  noneDefined,
}
