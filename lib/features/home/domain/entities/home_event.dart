import '../../../../shared/components/widgets/rsvp_widget.dart';
import 'participant_photo.dart';

/// Home event entity for display in home page sections
/// Contains essential info needed for event cards
class HomeEventEntity {
  final String id;
  final String name;
  final String emoji;
  final DateTime? date;
  final DateTime? endDate;
  final String? location;
  final HomeEventStatus status;
  final int goingCount;
  final List<String> attendeeAvatars; // Profile picture URLs
  final List<String> attendeeNames; // Names of attendees
  final bool?
      userVote; // true = going, false = not going, null = pending/not voted
  final List<RsvpVote> allVotes; // All votes for the bottom sheet
  final int photoCount; // Total photos added (for Living/Recap)
  final int maxPhotos; // Maximum photos allowed (for Living/Recap)
  final List<ParticipantPhoto>
      participantPhotos; // Photo contributions by participant

  const HomeEventEntity({
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

  /// Check if event date has expired
  /// Returns true when event is in pending status and start date has passed
  bool get isExpired {
    if (status != HomeEventStatus.pending) return false;
    if (date == null) return false;
    return DateTime.now().isAfter(date!);
  }

  HomeEventEntity copyWith({
    String? id,
    String? name,
    String? emoji,
    DateTime? date,
    DateTime? endDate,
    String? location,
    HomeEventStatus? status,
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
    return HomeEventEntity(
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
}

/// Status of a home event
/// Pending: waiting for confirmation
/// Confirmed: planning phase confirmed
/// Living: event is happening now
/// Recap: event ended, in recap phase
enum HomeEventStatus { pending, confirmed, living, recap }
