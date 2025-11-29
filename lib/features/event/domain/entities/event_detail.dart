/// Event detail domain entity
/// Extended event information for the event detail page
class EventDetail {
  final String id;
  final String name;
  final String emoji;
  final String groupId;
  final String? groupName; // Nome do grupo para exibição
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final EventLocation? location;
  final EventStatus status;
  final DateTime createdAt;
  final String hostId;
  final int goingCount;
  final int notGoingCount;

  const EventDetail({
    required this.id,
    required this.name,
    required this.emoji,
    required this.groupId,
    this.groupName,
    this.startDateTime,
    this.endDateTime,
    this.location,
    required this.status,
    required this.createdAt,
    required this.hostId,
    required this.goingCount,
    required this.notGoingCount,
  });

  EventDetail copyWith({
    String? id,
    String? name,
    String? emoji,
    String? groupId,
    String? groupName,
    DateTime? startDateTime,
    DateTime? endDateTime,
    EventLocation? location,
    EventStatus? status,
    DateTime? createdAt,
    String? hostId,
    int? goingCount,
    int? notGoingCount,
  }) {
    return EventDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      hostId: hostId ?? this.hostId,
      goingCount: goingCount ?? this.goingCount,
      notGoingCount: notGoingCount ?? this.notGoingCount,
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
enum EventStatus { pending, confirmed, ended }
