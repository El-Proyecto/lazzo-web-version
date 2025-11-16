import '../../../../shared/components/widgets/rsvp_widget.dart';
import '../../../home/domain/entities/participant_photo.dart';

/// Group event entity for display in group hub
/// Contains essential info needed for event cards in the Events section
class GroupEventEntity {
  final String id;
  final String name;
  final String emoji;
  final DateTime? date;
  final DateTime? endDate; // For Living/Recap states time-left display
  final String? location;
  final GroupEventStatus status;
  final int goingCount;
  final List<String> attendeeAvatars; // Profile picture URLs
  final List<String> attendeeNames; // Names of attendees
  final bool?
      userVote; // true = going, false = not going, null = pending/not voted
  final List<RsvpVote> allVotes; // All votes for the bottom sheet
  final int photoCount; // Total photos uploaded (for Living/Recap)
  final int maxPhotos; // Maximum photos allowed (for Living/Recap)
  final List<ParticipantPhoto> participantPhotos; // Photo contributions by user

  const GroupEventEntity({
    required this.id,
    required this.name,
    required this.emoji,
    this.date,
    this.endDate,
    this.location,
    required this.status,
    required this.goingCount,
    required this.attendeeAvatars,
    required this.attendeeNames,
    this.userVote,
    this.allVotes = const [],
    this.photoCount = 0,
    this.maxPhotos = 0,
    this.participantPhotos = const [],
  });

  GroupEventEntity copyWith({
    String? id,
    String? name,
    String? emoji,
    DateTime? date,
    DateTime? endDate,
    String? location,
    GroupEventStatus? status,
    int? goingCount,
    List<String>? attendeeAvatars,
    List<String>? attendeeNames,
    bool? userVote,
    List<RsvpVote>? allVotes,
    int? photoCount,
    int? maxPhotos,
    List<ParticipantPhoto>? participantPhotos,
    bool updateUserVote = false, // Flag to allow explicit null setting
  }) {
    return GroupEventEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      status: status ?? this.status,
      goingCount: goingCount ?? this.goingCount,
      attendeeAvatars: attendeeAvatars ?? this.attendeeAvatars,
      attendeeNames: attendeeNames ?? this.attendeeNames,
      userVote: updateUserVote ? userVote : (userVote ?? this.userVote),
      allVotes: allVotes ?? this.allVotes,
      photoCount: photoCount ?? this.photoCount,
      maxPhotos: maxPhotos ?? this.maxPhotos,
      participantPhotos: participantPhotos ?? this.participantPhotos,
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
        other.endDate == endDate &&
        other.location == location &&
        other.status == status &&
        other.goingCount == goingCount &&
        other.attendeeAvatars == attendeeAvatars &&
        other.attendeeNames == attendeeNames &&
        other.userVote == userVote &&
        other.allVotes == allVotes &&
        other.photoCount == photoCount &&
        other.maxPhotos == maxPhotos &&
        other.participantPhotos == participantPhotos;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      emoji,
      date,
      endDate,
      location,
      status,
      goingCount,
      attendeeAvatars,
      attendeeNames,
      userVote,
      Object.hashAll(allVotes),
      photoCount,
      maxPhotos,
      Object.hashAll(participantPhotos),
    );
  }
}

/// Status of a group event
enum GroupEventStatus { pending, confirmed, living, recap }
