// DTO models for Suggestions - maps Supabase JSON to/from domain entities

import '../../domain/entities/suggestion.dart';

/// Datetime Suggestion DTO Model
class SuggestionModel {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final DateTime createdAt;

  const SuggestionModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.startDateTime,
    this.endDateTime,
    required this.createdAt,
  });

  /// Create model from Supabase JSON (with user join)
  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user data from join
    final userData = json['user'] as Map<String, dynamic>?;
    
    return SuggestionModel(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['created_by'] as String, // Field: created_by
      userName: userData?['name'] as String? ?? 'Unknown User',
      userAvatar: userData?['avatar_url'] as String?,
      startDateTime: DateTime.parse(json['starts_at'] as String), // Field: starts_at
      endDateTime: json['ends_at'] != null // Field: ends_at
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert model to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'created_by': userId, // Field: created_by
      'starts_at': startDateTime.toIso8601String(), // Field: starts_at
      'ends_at': endDateTime?.toIso8601String(), // Field: ends_at
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to domain entity
  Suggestion toEntity() {
    return Suggestion(
      id: id,
      eventId: eventId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      createdAt: createdAt,
    );
  }

  /// Create model from domain entity
  factory SuggestionModel.fromEntity(Suggestion entity) {
    return SuggestionModel(
      id: entity.id,
      eventId: entity.eventId,
      userId: entity.userId,
      userName: entity.userName,
      userAvatar: entity.userAvatar,
      startDateTime: entity.startDateTime,
      endDateTime: entity.endDateTime,
      createdAt: entity.createdAt,
    );
  }
}

/// Location Suggestion DTO Model
class LocationSuggestionModel {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String locationName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const LocationSuggestionModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.locationName,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  /// Create model from Supabase JSON (with user join)
  factory LocationSuggestionModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user data from join
    final userData = json['user'] as Map<String, dynamic>?;
    
    return LocationSuggestionModel(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      userName: userData?['name'] as String? ?? 'Unknown User',
      userAvatar: userData?['avatar_url'] as String?,
      locationName: json['location_name'] as String,
      address: json['address'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert model to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'location_name': locationName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to domain entity
  LocationSuggestion toEntity() {
    return LocationSuggestion(
      id: id,
      eventId: eventId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      locationName: locationName,
      address: address,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
    );
  }

  /// Create model from domain entity
  factory LocationSuggestionModel.fromEntity(LocationSuggestion entity) {
    return LocationSuggestionModel(
      id: entity.id,
      eventId: entity.eventId,
      userId: entity.userId,
      userName: entity.userName,
      userAvatar: entity.userAvatar,
      locationName: entity.locationName,
      address: entity.address,
      latitude: entity.latitude,
      longitude: entity.longitude,
      createdAt: entity.createdAt,
    );
  }
}

/// Suggestion Vote DTO Model (for event_date_votes table)
class SuggestionVoteModel {
  final String optionId; // Field: option_id (for event_date_votes)
  final String userId;
  final String userName;
  final String? userAvatar;
  final DateTime votedAt; // Field: voted_at
  final String eventId;

  const SuggestionVoteModel({
    required this.optionId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.votedAt,
    required this.eventId,
  });

  /// Create model from Supabase JSON (with user join)
  factory SuggestionVoteModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user data from join
    final userData = json['user'] as Map<String, dynamic>?;
    
    return SuggestionVoteModel(
      optionId: json['option_id'] as String, // Field: option_id
      userId: json['user_id'] as String,
      userName: userData?['name'] as String? ?? 'Unknown User',
      userAvatar: userData?['avatar_url'] as String?,
      votedAt: DateTime.parse(json['voted_at'] as String), // Field: voted_at
      eventId: json['event_id'] as String,
    );
  }

  /// Convert model to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'option_id': optionId, // Field: option_id
      'user_id': userId,
      'voted_at': votedAt.toIso8601String(), // Field: voted_at
      'event_id': eventId,
    };
  }

  /// Convert to domain entity
  SuggestionVote toEntity() {
    return SuggestionVote(
      id: optionId, // Use optionId as id for domain entity
      suggestionId: optionId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      createdAt: votedAt, // Map votedAt to createdAt for domain entity
    );
  }

  /// Create model from domain entity
  factory SuggestionVoteModel.fromEntity(SuggestionVote entity) {
    return SuggestionVoteModel(
      optionId: entity.suggestionId,
      userId: entity.userId,
      userName: entity.userName,
      userAvatar: entity.userAvatar,
      votedAt: entity.createdAt,
      eventId: '', // Will be provided by context
    );
  }
}
