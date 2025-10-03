import '../../domain/entities/event.dart';

/// Data Transfer Object for EventLocation
/// Handles JSON serialization/deserialization and entity conversion
class LocationModel {
  final String id;
  final String? displayName;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  LocationModel({
    required this.id,
    this.displayName,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  /// Create LocationModel from Supabase row
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      formattedAddress: json['formatted_address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  /// Convert LocationModel to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'formatted_address': formattedAddress,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Convert LocationModel to domain Entity
  /// This bridges the data layer to domain layer
  EventLocation toEntity() {
    return EventLocation(
      id: id,
      displayName: displayName ?? formattedAddress, // Fallback to formatted address
      formattedAddress: formattedAddress,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Create LocationModel from domain Entity
  factory LocationModel.fromEntity(EventLocation location) {
    return LocationModel(
      id: location.id,
      displayName: location.displayName,
      formattedAddress: location.formattedAddress,
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }
}