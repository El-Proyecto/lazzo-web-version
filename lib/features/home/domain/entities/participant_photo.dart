/// Represents a participant's photo contribution to an event
/// Used in Living and Recap states to track photo uploads
class ParticipantPhoto {
  final String userId;
  final String userName;
  final String? userAvatar;
  final int photoCount;

  const ParticipantPhoto({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.photoCount,
  });

  ParticipantPhoto copyWith({
    String? userId,
    String? userName,
    String? userAvatar,
    int? photoCount,
  }) {
    return ParticipantPhoto(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      photoCount: photoCount ?? this.photoCount,
    );
  }
}
