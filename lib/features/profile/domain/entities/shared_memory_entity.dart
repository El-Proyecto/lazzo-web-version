/// Domain entity representing a shared memory (past event) between current user and another user
/// Contains minimal information for displaying memory cards in other user profiles
class SharedMemoryEntity {
  final String id;
  final String title;
  final String? emoji;
  final DateTime? date;
  final String? location;
  final String? coverPhotoUrl; // Signed URL for cover photo

  const SharedMemoryEntity({
    required this.id,
    required this.title,
    this.emoji,
    this.date,
    this.location,
    this.coverPhotoUrl,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SharedMemoryEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
