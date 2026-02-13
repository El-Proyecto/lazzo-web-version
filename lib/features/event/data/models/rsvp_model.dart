// DTO model for RSVP - maps Supabase JSON to/from domain entity

import '../../domain/entities/rsvp.dart';

/// RSVP DTO Model
/// Maps event_participants table to RSVP entity
class RsvpModel {
  final String userId;
  final String eventId;
  final String userName;
  final String? userAvatar;
  final String status;
  final DateTime? confirmedAt;

  const RsvpModel({
    required this.userId,
    required this.eventId,
    required this.userName,
    this.userAvatar,
    required this.status,
    this.confirmedAt,
  });

  /// Create model from Supabase JSON (event_participants table with user join)
  factory RsvpModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user data from join
    final userData = json['user'] as Map<String, dynamic>?;

    return RsvpModel(
      userId: json['user_id'] as String,
      eventId:
          json['pevent_id'] as String, // event_participants uses 'pevent_id'
      userName: userData?['name'] as String? ?? 'Unknown User',
      userAvatar: userData?['avatar_url'] as String?,
      status: json['rsvp'] as String? ??
          'pending', // event_participants uses 'rsvp' column
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
    );
  }

  /// Convert model to Supabase JSON (for event_participants table)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'pevent_id': eventId,
      'rsvp': status,
      if (confirmedAt != null) 'confirmed_at': confirmedAt!.toIso8601String(),
    };
  }

  /// Convert to domain entity
  Rsvp toEntity() {
    // Parse status enum (rsvp_status: pending, yes, no, maybe)
    RsvpStatus statusEnum;
    switch (status.toLowerCase()) {
      case 'yes':
        statusEnum = RsvpStatus.going;
        break;
      case 'no':
        statusEnum = RsvpStatus.notGoing;
        break;
      case 'maybe':
        statusEnum = RsvpStatus.maybe;
        break;
      case 'pending':
      default:
        statusEnum = RsvpStatus.pending;
    }

    return Rsvp(
      id: userId, // Use userId as ID since event_participants has composite PK
      eventId: eventId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      status: statusEnum,
      createdAt: confirmedAt ?? DateTime.now(),
    );
  }

  /// Create model from domain entity
  factory RsvpModel.fromEntity(Rsvp entity) {
    // Convert enum to string (rsvp_status: pending, yes, no, maybe)
    String statusString;
    switch (entity.status) {
      case RsvpStatus.going:
        statusString = 'yes';
        break;
      case RsvpStatus.notGoing:
        statusString = 'no';
        break;
      case RsvpStatus.maybe:
        statusString = 'maybe';
        break;
      case RsvpStatus.pending:
        statusString = 'pending';
        break;
    }

    return RsvpModel(
      userId: entity.userId,
      eventId: entity.eventId,
      userName: entity.userName,
      userAvatar: entity.userAvatar,
      status: statusString,
      confirmedAt: entity.createdAt,
    );
  }
}
