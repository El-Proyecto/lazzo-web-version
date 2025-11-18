import '../../domain/entities/group_event_entity.dart';
import '../../../../shared/components/widgets/rsvp_widget.dart';

/// DTO for converting Supabase JSON (from group_hub_events_view) to GroupEventEntity
class GroupEventModel {
  /// Convert Supabase JSON from group_hub_events_view to GroupEventEntity
  static GroupEventEntity fromJson(Map<String, dynamic> json, {List<Map<String, dynamic>>? rsvps}) {
    // Parse dates
    final startDate = json['start_datetime'] != null 
        ? DateTime.parse(json['start_datetime']) 
        : null;
    final endDate = json['end_datetime'] != null 
        ? DateTime.parse(json['end_datetime']) 
        : null;

    // Parse status from event_state enum
    final status = _statusFromString(json['event_status'] ?? 'pending');

    // Parse going users for avatars and names
    final goingUsers = (json['going_users'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final attendeeAvatars = goingUsers
        .map((u) => u['avatar_url'] as String?)
        .whereType<String>()
        .toList();
    final attendeeNames = goingUsers
        .map((u) => u['display_name'] as String?)
        .whereType<String>()
        .toList();

    // Parse current user's RSVP
    final userRsvp = json['current_user_rsvp'] as String?;
    final userVote = userRsvp == null || userRsvp == 'pending' || userRsvp == 'invited'
        ? null
        : (userRsvp == 'going' || userRsvp == 'yes' || userRsvp == 'attending' || userRsvp == 'accepted');

    // Parse all votes if provided
    final allVotes = rsvps?.map((r) => RsvpVote(
      id: r['user_id'] ?? '',
      userId: r['user_id'] ?? '',
      userName: r['user_name'] ?? '',
      userAvatar: r['user_avatar'],
      status: _parseRsvpStatus(r['status'] ?? 'pending'),
      votedAt: r['voted_at'] != null ? DateTime.parse(r['voted_at']) : null,
    )).toList() ?? [];

    return GroupEventEntity(
      id: json['event_id'] ?? '',
      name: json['event_name'] ?? '',
      emoji: json['emoji'] ?? '📅',
      date: startDate,
      endsAt: endDate,
      location: json['location_name'],
      status: status,
      goingCount: json['going_count'] ?? 0,
      participantCount: json['participants_total'] ?? 0,
      photoCount: json['photo_count'] ?? 0,
      maxPhotos: json['max_photos'],
      attendeeAvatars: attendeeAvatars,
      attendeeNames: attendeeNames,
      userVote: userVote,
      allVotes: allVotes,
    );
  }

  /// Helper to convert RSVP status string to enum
  static RsvpVoteStatus _parseRsvpStatus(String status) {
    switch (status.toLowerCase()) {
      case 'going':
      case 'yes':
      case 'attending':
      case 'accepted':
        return RsvpVoteStatus.going;
      case 'notgoing':
      case 'not_going':
      case 'declined':
      case 'no':
      case 'rejected':
        return RsvpVoteStatus.notGoing;
      case 'pending':
      case 'invited':
      default:
        return RsvpVoteStatus.pending;
    }
  }

  /// Helper to convert event_state string to GroupEventStatus enum
  static GroupEventStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return GroupEventStatus.confirmed;
      case 'living':  // Supabase usa 'living' não 'live'
        return GroupEventStatus.live;
      case 'recap':
        return GroupEventStatus.recap;
      case 'pending':
      default:
        return GroupEventStatus.pending;
    }
  }
}
