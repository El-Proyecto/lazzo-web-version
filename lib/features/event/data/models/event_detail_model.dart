// DTO model for EventDetail - maps Supabase JSON to/from domain entity

import '../../domain/entities/event_detail.dart';

/// EventDetail DTO Model
class EventDetailModel {
  final String id;
  final String name;
  final String emoji;
  final String groupId;
  final String? groupName;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? locationName;
  final String? locationAddress;
  final double? locationLatitude;
  final double? locationLongitude;
  final String status;
  final DateTime createdAt;
  final String hostId;
  final int goingCount;
  final int notGoingCount;

  const EventDetailModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.groupId,
    this.groupName,
    this.startDateTime,
    this.endDateTime,
    this.locationName,
    this.locationAddress,
    this.locationLatitude,
    this.locationLongitude,
    required this.status,
    required this.createdAt,
    required this.hostId,
    required this.goingCount,
    required this.notGoingCount,
  });

  /// Create model from Supabase JSON
  factory EventDetailModel.fromJson(Map<String, dynamic> json) {
    final statusFromDb = json['status'] as String? ?? 'pending';

    return EventDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '📅',
      groupId: json['group_id'] as String,
      groupName: json['group_name'] as String?,
      startDateTime: json['start_datetime'] != null
          ? DateTime.parse(json['start_datetime'] as String)
          : null,
      endDateTime: json['end_datetime'] != null
          ? DateTime.parse(json['end_datetime'] as String)
          : null,
      locationName: json['location_name'] as String?,
      locationAddress: json['location_address'] as String?,
      locationLatitude: json['location_latitude'] as double?,
      locationLongitude: json['location_longitude'] as double?,
      status: statusFromDb,
      createdAt: DateTime.parse(json['created_at'] as String),
      hostId: json['host_id'] as String,
      goingCount: json['rsvp_going_count'] as int? ?? 0,
      notGoingCount: json['rsvp_not_going_count'] as int? ?? 0,
    );
  }

  /// Convert model to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'group_id': groupId,
      'group_name': groupName,
      'start_datetime': startDateTime?.toIso8601String(),
      'end_datetime': endDateTime?.toIso8601String(),
      'location_name': locationName,
      'location_address': locationAddress,
      'location_latitude': locationLatitude,
      'location_longitude': locationLongitude,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'host_id': hostId,
    };
  }

  /// Convert to domain entity
  EventDetail toEntity() {
    // Parse status enum
    EventStatus statusEnum;
    final statusLower = status.toLowerCase();

    
    switch (statusLower) {
      case 'confirmed':
        statusEnum = EventStatus.confirmed;
                break;
      case 'living':
        statusEnum = EventStatus.living;
                break;
      case 'recap':
        statusEnum = EventStatus.recap;
                break;
      default:
        statusEnum = EventStatus.pending;
            }

    // Create location if all fields present
    EventLocation? location;
    if (locationName != null &&
        locationAddress != null &&
        locationLatitude != null &&
        locationLongitude != null) {
      location = EventLocation(
        id: id, // Use event ID as location ID for now
        displayName: locationName!,
        formattedAddress: locationAddress!,
        latitude: locationLatitude!,
        longitude: locationLongitude!,
      );
    }

    return EventDetail(
      id: id,
      name: name,
      emoji: emoji,
      groupId: groupId,
      groupName: groupName,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      location: location,
      status: statusEnum,
      createdAt: createdAt,
      hostId: hostId,
      goingCount: goingCount,
      notGoingCount: notGoingCount,
    );
  }

  /// Create model from domain entity
  factory EventDetailModel.fromEntity(EventDetail entity) {
    return EventDetailModel(
      id: entity.id,
      name: entity.name,
      emoji: entity.emoji,
      groupId: entity.groupId,
      groupName: entity.groupName,
      startDateTime: entity.startDateTime,
      endDateTime: entity.endDateTime,
      locationName: entity.location?.displayName,
      locationAddress: entity.location?.formattedAddress,
      locationLatitude: entity.location?.latitude,
      locationLongitude: entity.location?.longitude,
      status: entity.status.name,
      createdAt: entity.createdAt,
      hostId: entity.hostId,
      goingCount: entity.goingCount,
      notGoingCount: entity.notGoingCount,
    );
  }
}
