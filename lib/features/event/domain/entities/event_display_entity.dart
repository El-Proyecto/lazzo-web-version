import '../../../../shared/components/widgets/rsvp_widget.dart';
import '../../../home/domain/entities/participant_photo.dart';

/// Event display entity for event cards across the app
/// Contains essential info needed for full event cards (EventFullCard, etc.)
/// Replaces the former GroupEventEntity (Lazzo 2.0: groups removed)
class EventDisplayEntity {
  final String id;
  final String name;
  final String emoji;
  final DateTime? date;
  final DateTime? endDate;
  final String? location;
  final EventDisplayStatus status;
  final int goingCount;
  final int participantCount;
  final List<String> attendeeAvatars;
  final List<String> attendeeNames;
  final RsvpVoteStatus userVote;
  final List<RsvpVote> allVotes;
  final int photoCount;
  final int maxPhotos;
  final List<ParticipantPhoto> participantPhotos;

  const EventDisplayEntity({
    required this.id,
    required this.name,
    required this.emoji,
    this.date,
    this.endDate,
    this.location,
    required this.status,
    required this.goingCount,
    required this.participantCount,
    required this.attendeeAvatars,
    required this.attendeeNames,
    this.userVote = RsvpVoteStatus.pending,
    this.allVotes = const [],
    this.photoCount = 0,
    this.maxPhotos = 0,
    this.participantPhotos = const [],
  });

  EventDisplayEntity copyWith({
    String? id,
    String? name,
    String? emoji,
    DateTime? date,
    DateTime? endDate,
    String? location,
    EventDisplayStatus? status,
    int? goingCount,
    int? participantCount,
    int? photoCount,
    int? maxPhotos,
    List<String>? attendeeAvatars,
    List<String>? attendeeNames,
    RsvpVoteStatus? userVote,
    List<RsvpVote>? allVotes,
    List<ParticipantPhoto>? participantPhotos,
  }) {
    return EventDisplayEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      status: status ?? this.status,
      goingCount: goingCount ?? this.goingCount,
      participantCount: participantCount ?? this.participantCount,
      attendeeAvatars: attendeeAvatars ?? this.attendeeAvatars,
      attendeeNames: attendeeNames ?? this.attendeeNames,
      userVote: userVote ?? this.userVote,
      allVotes: allVotes ?? this.allVotes,
      photoCount: photoCount ?? this.photoCount,
      maxPhotos: maxPhotos ?? this.maxPhotos,
      participantPhotos: participantPhotos ?? this.participantPhotos,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventDisplayEntity &&
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

/// Status of an event for display purposes
enum EventDisplayStatus { pending, confirmed, living, recap, expired }
