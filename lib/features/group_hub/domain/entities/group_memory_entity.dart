import '../../../../shared/components/sections/memories_section.dart';

/// Group memory entity for display in group hub
/// Contains essential info needed for memory cards in the Memories section
class GroupMemoryEntity implements MemoryData {
  final String id;
  final String title;
  final String? location;
  final DateTime date;
  final String coverImageUrl;
  final int photoCount;

  const GroupMemoryEntity({
    required this.id,
    required this.title,
    this.location,
    required this.date,
    required this.coverImageUrl,
    required this.photoCount,
  });

  // Implement MemoryData interface
  String get memoryId => id;

  String get memoryTitle => title;

  String? get memoryCoverPhotoUrl => coverImageUrl;

  DateTime get memoryCreatedAt => date;

  int get memoryPhotoCount => photoCount;

  GroupMemoryEntity copyWith({
    String? id,
    String? title,
    String? location,
    DateTime? date,
    String? coverImageUrl,
    int? photoCount,
  }) {
    return GroupMemoryEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      date: date ?? this.date,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      photoCount: photoCount ?? this.photoCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMemoryEntity &&
        other.id == id &&
        other.title == title &&
        other.location == location &&
        other.date == date &&
        other.coverImageUrl == coverImageUrl &&
        other.photoCount == photoCount;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, location, date, coverImageUrl, photoCount);
  }
}
