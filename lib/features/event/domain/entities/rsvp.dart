/// RSVP domain entity
/// Represents a user's response to an event
class Rsvp {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? userEmail;
  final RsvpStatus status;
  final DateTime createdAt;

  const Rsvp({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.userEmail,
    required this.status,
    required this.createdAt,
  });

  Rsvp copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? userEmail,
    RsvpStatus? status,
    DateTime? createdAt,
  }) {
    return Rsvp(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      userEmail: userEmail ?? this.userEmail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// RSVP status enumeration
enum RsvpStatus { going, notGoing, maybe, pending }
