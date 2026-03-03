/// Event domain entity
/// Pure Dart model representing an event in the domain layer
class Event {
  final String id;
  final String name;
  final String emoji;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final EventLocation? location;
  final EventStatus status;
  final DateTime createdAt;
  final String? description;

  const Event({
    required this.id,
    required this.name,
    required this.emoji,
    this.startDateTime,
    this.endDateTime,
    this.location,
    required this.status,
    required this.createdAt,
    this.description,
  });

  /// Copy event with updated fields
  /// CRITICAL: Uses explicit ValueWrapper to allow clearing nullable fields
  /// This is essential for "Decide Later" functionality (clearing dates/location)
  Event copyWith({
    String? id,
    String? name,
    String? emoji,
    ValueWrapper<DateTime?>? startDateTime,
    ValueWrapper<DateTime?>? endDateTime,
    ValueWrapper<EventLocation?>? location,
    EventStatus? status,
    DateTime? createdAt,
    ValueWrapper<String?>? description,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      startDateTime:
          startDateTime != null ? startDateTime.value : this.startDateTime,
      endDateTime: endDateTime != null ? endDateTime.value : this.endDateTime,
      location: location != null ? location.value : this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      description: description != null ? description.value : this.description,
    );
  }
}

/// Wrapper to distinguish between "not provided" and "explicitly null"
/// Required for copyWith to allow clearing nullable fields
class ValueWrapper<T> {
  final T value;
  const ValueWrapper(this.value);
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
enum EventStatus { pending, confirmed, living, recap, expired }
