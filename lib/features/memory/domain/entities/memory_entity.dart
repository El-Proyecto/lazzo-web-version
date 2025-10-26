/// Memory entity representing a completed event with photos
class MemoryEntity {
  final String id;
  final String eventId;
  final String title;
  final String? location;
  final DateTime eventDate;
  final List<MemoryPhoto> photos;

  const MemoryEntity({
    required this.id,
    required this.eventId,
    required this.title,
    this.location,
    required this.eventDate,
    required this.photos,
  });

  /// Get cover photos (up to 3, sorted by votes)
  List<MemoryPhoto> get coverPhotos => photos.where((p) => p.isCover).toList();

  /// Get non-cover photos for the grid
  List<MemoryPhoto> get gridPhotos {
    final coverIds = coverPhotos.map((p) => p.id).toSet();
    return photos.where((p) => !coverIds.contains(p.id)).toList()
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
  }
}

/// Individual photo in a memory
class MemoryPhoto {
  final String id;
  final String url;
  final String? thumbnailUrl; // 512px for grid
  final String? coverUrl; // 1024px for cover mosaic
  final int voteCount;
  final DateTime capturedAt;
  final double aspectRatio; // width / height
  final String uploaderId;
  final String uploaderName;
  final bool isCover; // NOVO

  const MemoryPhoto({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.coverUrl,
    required this.voteCount,
    required this.capturedAt,
    required this.aspectRatio,
    required this.uploaderId,
    required this.uploaderName,
    required this.isCover,
  });

  /// Returns true if photo is portrait (vertical)
  bool get isPortrait => aspectRatio < 1.0;

  /// Returns true if photo is landscape (horizontal)
  bool get isLandscape => aspectRatio >= 1.0;
}
