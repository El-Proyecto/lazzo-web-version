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

    // Parse status: use computed_status from view
    final status = _statusFromString(json['computed_status'] ?? json['event_status'] ?? 'pending');

    // Parse going users for avatars and names
    final goingUsersJson = json['going_users'];
    final goingUsers = goingUsersJson is List 
        ? goingUsersJson.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    
    final attendeeAvatars = goingUsers
        .map((u) => u['avatar_url'] as String?)
        .whereType<String>()
        .toList();
    final attendeeNames = goingUsers
        .map((u) => u['full_name'] as String?)
        .whereType<String>()
        .toList();

    // Parse current user's RSVP
    final userRsvp = json['current_user_rsvp'] as String?;
    final userVote = userRsvp == null || userRsvp == 'pending' || userRsvp == 'invited'
        ? null
        : (userRsvp == 'going' || userRsvp == 'yes' || userRsvp == 'attending' || userRsvp == 'accepted');

    // Parse all votes if provided
    final allVotes = rsvps?.map((r) {
      final vote = RsvpVote(
        id: r['user_id'] ?? '',
        userId: r['user_id'] ?? '',
        userName: r['user_name'] ?? '',
        userAvatar: r['user_avatar'],
        status: _parseRsvpStatus(r['status'] ?? 'pending'),
        votedAt: r['voted_at'] != null ? DateTime.parse(r['voted_at']) : null,
      );
      print('🔍 [MODEL] Parsed vote for ${vote.userName}:');
      print('   🎨 Avatar after DTO: ${vote.userAvatar}');
      return vote;
    }).toList() ?? [];

    // Calculate participant count from GOING users only (not all votes)
    // Participant count = users who voted "going", not total voters
    final goingVotes = allVotes.where((v) => v.status == RsvpVoteStatus.going).length;
    final goingCount = json['rsvp_going'] ?? 0;
    
    // Use going votes count if available, otherwise use DB going count
    final calculatedParticipantCount = allVotes.isNotEmpty 
        ? goingVotes
        : goingCount;
    
    print('📊 [MODEL] Event ${json['event_id']}:');
    print('   🎯 Going count from DB: $goingCount');
    print('   ✅ Going votes parsed: $goingVotes');
    print('   👥 Participant count from DB: ${json['participant_count']}');
    print('   🧮 Calculated participant count: $calculatedParticipantCount');
    print('   📋 Total votes (all statuses): ${allVotes.length}');
    print('   👤 Attendee avatars from going_users: ${attendeeAvatars.length}');

    return GroupEventEntity(
      id: json['event_id'] ?? '',
      name: json['title'] ?? '',
      emoji: json['emoji'] ?? '📅',
      date: startDate,
      endDate: endDate,
      location: json['location_name'],
      status: status,
      goingCount: goingCount,
      participantCount: calculatedParticipantCount,
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
        return GroupEventStatus.living;
      case 'recap':
        return GroupEventStatus.recap;
      case 'pending':
      default:
        return GroupEventStatus.pending;
    }
  }
}
