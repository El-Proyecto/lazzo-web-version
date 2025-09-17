/// Event domain entity
/// Pure Dart model representing an event in the domain layer
class Event {
  final String id;
  final String name;
  final String emoji;
  final String groupId;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final EventLocation? location;
  final EventStatus status;
  final DateTime createdAt;

  const Event({
    required this.id,
    required this.name,
    required this.emoji,
    required this.groupId,
    this.startDateTime,
    this.endDateTime,
    this.location,
    required this.status,
    required this.createdAt,
  });

  Event copyWith({
    String? id,
    String? name,
    String? emoji,
    String? groupId,
    DateTime? startDateTime,
    DateTime? endDateTime,
    EventLocation? location,
    EventStatus? status,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      groupId: groupId ?? this.groupId,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
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
enum EventStatus { draft, planning, confirmed, cancelled, completed }
