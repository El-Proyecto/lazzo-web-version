import '../../domain/entities/event_history.dart';

/// DTO for event history data from Supabase
/// Maps JSON from events + locations tables to EventHistory entity
class EventHistoryModel {
  final String id;
  final String name;
  final String emoji;
  final DateTime startDateTime;
  final String? locationId;
  final String? locationName;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final String groupId;
  final String? groupName;
  final DateTime createdAt;

  const EventHistoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.startDateTime,
    this.locationId,
    this.locationName,
    this.locationAddress,
    this.latitude,
    this.longitude,
    required this.groupId,
    this.groupName,
    required this.createdAt,
  });

  /// Parse from Supabase JSON row
  /// Handles joined location data from LEFT JOIN
  factory EventHistoryModel.fromJson(Map<String, dynamic> json) {
    // Parse location data if present (from JOIN)
    final locationData = json['locations'] as Map<String, dynamic>?;

    return EventHistoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      startDateTime: DateTime.parse(json['start_datetime'] as String),
      locationId: json['location_id'] as String?,
      locationName: locationData?['display_name'] as String?,
      locationAddress: locationData?['formatted_address'] as String?,
      latitude: locationData?['latitude'] as double?,
      longitude: locationData?['longitude'] as double?,
      groupId: json['group_id'] as String? ?? '',
      groupName: null, // LAZZO 2.0: groups removed
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to domain entity
  EventHistory toEntity() {
    return EventHistory(
      id: id,
      name: name,
      emoji: emoji,
      startDateTime: startDateTime,
      locationId: locationId,
      locationName: locationName,
      locationAddress: locationAddress,
      latitude: latitude,
      longitude: longitude,
      groupId: groupId,
      groupName: groupName,
      createdAt: createdAt,
    );
  }

  /// Convert from domain entity (rarely used for history)
  factory EventHistoryModel.fromEntity(EventHistory entity) {
    return EventHistoryModel(
      id: entity.id,
      name: entity.name,
      emoji: entity.emoji,
      startDateTime: entity.startDateTime,
      locationId: entity.locationId,
      locationName: entity.locationName,
      locationAddress: entity.locationAddress,
      latitude: entity.latitude,
      longitude: entity.longitude,
      groupId: entity.groupId,
      groupName: entity.groupName,
      createdAt: entity.createdAt,
    );
  }

  /// Convert to JSON (for testing/debugging)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'start_datetime': startDateTime.toIso8601String(),
      'location_id': locationId,
      'created_at': createdAt.toIso8601String(),
      if (locationName != null)
        'locations': {
          'display_name': locationName,
          'formatted_address': locationAddress,
          'latitude': latitude,
          'longitude': longitude,
        },
    };
  }
}
