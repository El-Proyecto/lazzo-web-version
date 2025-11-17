import '../../domain/entities/group_event_entity.dart';
import '../../../../shared/components/widgets/rsvp_widget.dart';

/// DTO for converting Supabase JSON to GroupEventEntity
/// 
/// P2 Implementation Requirements:
/// - Parse all fields from Supabase JSON response
/// - Handle nullable fields gracefully with defaults
/// - Convert date strings to DateTime objects
/// - Map status strings to enum values
/// - Parse RSVP votes from joined data
class GroupEventModel {
  /// Convert Supabase JSON to GroupEventEntity
  /// 
  /// Expected JSON structure:
  /// ```json
  /// {
  ///   "id": "uuid",
  ///   "name": "Beach Day",
  ///   "emoji": "🏖️",
  ///   "date": "2025-11-20T14:00:00Z",
  ///   "ends_at": "2025-11-20T18:00:00Z",  // nullable
  ///   "location": "Cascais Beach",         // nullable
  ///   "status": "confirmed",               // "pending", "confirmed", "live", "recap"
  ///   "going_count": 5,
  ///   "participant_count": 7,
  ///   "photo_count": 18,
  ///   "max_photos": 30,                    // nullable
  ///   "attendee_avatars": ["url1", "url2"],
  ///   "attendee_names": ["Sarah", "Mike"],
  ///   "user_vote": true,                   // nullable: true/false/null
  ///   "rsvps": [                          // from getEventRsvps()
  ///     {
  ///       "id": "uuid",
  ///       "user_id": "uuid",
  ///       "user_name": "Sarah",
  ///       "user_avatar": "url",
  ///       "status": "going",               // "going", "notGoing", "pending"
  ///       "voted_at": "2025-11-15T10:00:00Z"
  ///     }
  ///   ]
  /// }
  /// ```
  static GroupEventEntity fromJson(Map<String, dynamic> json) {
    // P2 TODO: Implement JSON parsing
    // 
    // Implementation steps:
    // 1. Parse required fields (id, name, emoji, status, counts)
    // 2. Parse optional fields with null checks (date, endsAt, location, maxPhotos)
    // 3. Convert date strings to DateTime using DateTime.parse()
    // 4. Map status string to GroupEventStatus enum
    // 5. Parse attendee arrays (avatars, names)
    // 6. Parse RSVP votes array if present
    // 7. Return GroupEventEntity with all parsed data
    //
    // Example enum mapping:
    // final status = json['status'] == 'confirmed' 
    //     ? GroupEventStatus.confirmed
    //     : json['status'] == 'live'
    //     ? GroupEventStatus.live
    //     : json['status'] == 'recap'
    //     ? GroupEventStatus.recap
    //     : GroupEventStatus.pending;
    //
    // Example RSVP parsing:
    // final rsvps = (json['rsvps'] as List?)?.map((r) => RsvpVote(
    //   id: r['id'],
    //   userId: r['user_id'],
    //   userName: r['user_name'],
    //   userAvatar: r['user_avatar'],
    //   status: _parseRsvpStatus(r['status']),
    //   votedAt: r['voted_at'] != null ? DateTime.parse(r['voted_at']) : null,
    // )).toList() ?? [];

    throw UnimplementedError('P2: Implement JSON to GroupEventEntity conversion');
  }

  /// Helper to convert RSVP status string to enum
  // ignore: unused_element
  static RsvpVoteStatus _parseRsvpStatus(String status) {
    switch (status) {
      case 'going':
        return RsvpVoteStatus.going;
      case 'notGoing':
      case 'not_going':
        return RsvpVoteStatus.notGoing;
      case 'pending':
      default:
        return RsvpVoteStatus.pending;
    }
  }

  /// Helper to convert GroupEventStatus enum to string for Supabase
  static String statusToString(GroupEventStatus status) {
    switch (status) {
      case GroupEventStatus.pending:
        return 'pending';
      case GroupEventStatus.confirmed:
        return 'confirmed';
      case GroupEventStatus.live:
        return 'live';
      case GroupEventStatus.recap:
        return 'recap';
    }
  }

  /// Helper to convert string to GroupEventStatus enum
  static GroupEventStatus statusFromString(String status) {
    switch (status) {
      case 'confirmed':
        return GroupEventStatus.confirmed;
      case 'live':
        return GroupEventStatus.live;
      case 'recap':
        return GroupEventStatus.recap;
      case 'pending':
      default:
        return GroupEventStatus.pending;
    }
  }
}
