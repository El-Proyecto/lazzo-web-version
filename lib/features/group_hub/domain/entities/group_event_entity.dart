import '../../../../shared/components/widgets/rsvp_widget.dart';

/// Group event entity for display in group hub
/// Contains essential info needed for event cards in the Events section
class GroupEventEntity {
  final String id;
  final String name;
  final String emoji;
  final DateTime? date;
  final DateTime? endsAt; // For Live/Recap status - when event ends
  final String? location;
  final GroupEventStatus status;
  final int goingCount;
  final int participantCount; // Total participants (for "X participants")
  final int photoCount; // Current photos uploaded
  final int? maxPhotos; // Maximum photos allowed (for "X/Y photos")
  final List<String> attendeeAvatars; // Profile picture URLs
  final List<String> attendeeNames; // Names of attendees
  final bool?
      userVote; // true = going, false = not going, null = pending/not voted
  final List<RsvpVote> allVotes; // All votes for the bottom sheet

  const GroupEventEntity({
    required this.id,
    required this.name,
    required this.emoji,
    this.date,
    this.endsAt,
    this.location,
    required this.status,
    required this.goingCount,
    required this.participantCount,
    required this.photoCount,
    this.maxPhotos,
    required this.attendeeAvatars,
    required this.attendeeNames,
    this.userVote,
    this.allVotes = const [],
  });

  GroupEventEntity copyWith({
    String? id,
    String? name,
    String? emoji,
    DateTime? date,
    DateTime? endsAt,
    String? location,
    GroupEventStatus? status,
    int? goingCount,
    int? participantCount,
    int? photoCount,
    int? maxPhotos,
    List<String>? attendeeAvatars,
    List<String>? attendeeNames,
    bool? userVote,
    List<RsvpVote>? allVotes,
    bool updateUserVote = false, // Flag to allow explicit null setting
  }) {
    return GroupEventEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      date: date ?? this.date,
      endsAt: endsAt ?? this.endsAt,
      location: location ?? this.location,
      status: status ?? this.status,
      goingCount: goingCount ?? this.goingCount,
      participantCount: participantCount ?? this.participantCount,
      photoCount: photoCount ?? this.photoCount,
      maxPhotos: maxPhotos ?? this.maxPhotos,
      attendeeAvatars: attendeeAvatars ?? this.attendeeAvatars,
      attendeeNames: attendeeNames ?? this.attendeeNames,
      userVote: updateUserVote ? userVote : (userVote ?? this.userVote),
      allVotes: allVotes ?? this.allVotes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupEventEntity &&
        other.id == id &&
        other.name == name &&
        other.emoji == emoji &&
        other.date == date &&
        other.location == location &&
        other.status == status &&
        other.goingCount == goingCount &&
        other.attendeeAvatars == attendeeAvatars &&
        other.attendeeNames == attendeeNames &&
        other.userVote == userVote &&
        other.allVotes == allVotes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      emoji,
      date,
      location,
      status,
      goingCount,
      attendeeAvatars,
      attendeeNames,
      userVote,
      allVotes,
    );
  }
}

/// Status of a group event
enum GroupEventStatus { 
  pending,    // Event not yet confirmed
  confirmed,  // Event confirmed with date/time
  live,       // Event is happening now
  recap       // Event recently ended, recap period
}
