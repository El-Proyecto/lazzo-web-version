// Removed unused import
import '../../domain/entities/memory_entity.dart';
import '../../domain/repositories/memory_repository.dart';

/// Event status for memory page testing
enum FakeEventStatus { living, recap, ended }

/// Global test configuration for cover mosaic scenarios
/// Modify these values to test different layouts
class FakeMemoryConfig {
  /// Number of portrait photos in covers (0-3)
  static int coverPortraitCount = 2;

  /// Number of landscape photos in covers (0-3)
  static int coverLandscapeCount = 1;

  /// Number of portrait photos in grid (non-covers)
  static int gridPortraitCount = 1;

  /// Number of landscape photos in grid (non-covers)
  static int gridLandscapeCount = 1;

  /// Whether current user is host (can select all photos)
  static bool isHost = true;

  /// Current event status (living, recap, or ended)
  /// - living: event is happening now
  /// - recap: event ended, in recap phase
  /// - ended: event fully ended, memory is read-only
  static FakeEventStatus eventStatus = FakeEventStatus.recap;

  /// Whether current user has uploaded photos
  /// Used to determine if edit button should show in living/recap
  /// Set to false to test CTA banners, true to test cover selection
  static bool userHasUploadedPhotos = false;

  /// When the recap phase closes (null for living/ended)
  /// Used for countdown timer in AppBar
  /// Example: DateTime.now().add(Duration(hours: 2, minutes: 30))
  static DateTime? closeTime =
      DateTime.now().add(const Duration(hours: 2, minutes: 30));

  /// Max covers is 3
  static int get totalCovers => coverPortraitCount + coverLandscapeCount;

  /// Time remaining until recap closes
  static Duration? get remainingTime {
    if (closeTime == null) return null;
    final now = DateTime.now();
    final remaining = closeTime!.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Formatted time remaining (e.g., "2h 34m", "45m", "3m")
  static String get formattedRemainingTime {
    final remaining = remainingTime;
    if (remaining == null) return '';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h${minutes}m';
    }
    return '${minutes}m';
  }

  /// Whether time remaining is less than 1 hour
  static bool get isLessThanOneHour {
    final remaining = remainingTime;
    if (remaining == null) return false;
    return remaining.inHours < 1;
  }
}

class FakeMemoryRepository implements MemoryRepository {
  @override
  Future<MemoryEntity?> getMemoryById(String memoryId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _buildDynamicMemory();
  }

  @override
  Future<MemoryEntity?> getMemoryByEventId(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _buildDynamicMemory();
  }

  @override
  Future<String> shareMemory(String memoryId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'https://lazzo.app/memory/$memoryId';
  }

  @override
  Future<bool> updateCover(String memoryId, String? photoId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Fake implementation: always succeeds
    return true;
  }

  @override
  Future<bool> removePhoto(String memoryId, String photoId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Fake implementation: always succeeds
    return true;
  }

  @override
  Future<bool> closeRecap(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Fake implementation: simulate closing recap
    // In real implementation, this would:
    // 1. Validate at least one photo exists
    // 2. Set first photo as cover if none selected
    // 3. Change status from 'recap' to 'ended'
    return true;
  }
}

final DateTime _baseDate = DateTime(2024, 7, 5);

/// Build memory from dynamic config with fake photos based on FakeMemoryConfig
MemoryEntity _buildDynamicMemory() {
  final List<MemoryPhoto> photos = [];
  int photoIndex = 0;

  // Add cover photos (portrait)
  for (int i = 0; i < FakeMemoryConfig.coverPortraitCount; i++) {
    photos.add(MemoryPhoto(
      id: 'cover-portrait-$photoIndex',
      url: 'https://picsum.photos/seed/cover-portrait-$photoIndex/600/800',
      thumbnailUrl:
          'https://picsum.photos/seed/cover-portrait-$photoIndex/512/682',
      coverUrl:
          'https://picsum.photos/seed/cover-portrait-$photoIndex/1024/1365',
      voteCount: 0,
      capturedAt: _baseDate.add(Duration(hours: photoIndex)),
      aspectRatio: 0.75, // 600/800 = portrait
      uploaderId: 'user-123',
      uploaderName: 'User 123',
      profileImageUrl: null,
      isCover: true,
    ));
    photoIndex++;
  }

  // Add cover photos (landscape)
  for (int i = 0; i < FakeMemoryConfig.coverLandscapeCount; i++) {
    photos.add(MemoryPhoto(
      id: 'cover-landscape-$photoIndex',
      url: 'https://picsum.photos/seed/cover-landscape-$photoIndex/800/600',
      thumbnailUrl:
          'https://picsum.photos/seed/cover-landscape-$photoIndex/512/384',
      coverUrl:
          'https://picsum.photos/seed/cover-landscape-$photoIndex/1024/768',
      voteCount: 0,
      capturedAt: _baseDate.add(Duration(hours: photoIndex)),
      aspectRatio: 1.33, // 800/600 = landscape
      uploaderId: 'user-123',
      uploaderName: 'User 123',
      profileImageUrl: null,
      isCover: true,
    ));
    photoIndex++;
  }

  // Add grid photos (portrait)
  for (int i = 0; i < FakeMemoryConfig.gridPortraitCount; i++) {
    photos.add(MemoryPhoto(
      id: 'grid-portrait-$photoIndex',
      url: 'https://picsum.photos/seed/grid-portrait-$photoIndex/600/800',
      thumbnailUrl:
          'https://picsum.photos/seed/grid-portrait-$photoIndex/512/682',
      coverUrl:
          'https://picsum.photos/seed/grid-portrait-$photoIndex/1024/1365',
      voteCount: 0,
      capturedAt: _baseDate.add(Duration(hours: photoIndex)),
      aspectRatio: 0.75, // 600/800 = portrait
      uploaderId: 'user-456',
      uploaderName: 'User 456',
      profileImageUrl: null,
      isCover: false,
    ));
    photoIndex++;
  }

  // Add grid photos (landscape)
  for (int i = 0; i < FakeMemoryConfig.gridLandscapeCount; i++) {
    photos.add(MemoryPhoto(
      id: 'grid-landscape-$photoIndex',
      url: 'https://picsum.photos/seed/grid-landscape-$photoIndex/800/600',
      thumbnailUrl:
          'https://picsum.photos/seed/grid-landscape-$photoIndex/512/384',
      coverUrl:
          'https://picsum.photos/seed/grid-landscape-$photoIndex/1024/768',
      voteCount: 0,
      capturedAt: _baseDate.add(Duration(hours: photoIndex)),
      aspectRatio: 1.33, // 800/600 = landscape
      uploaderId: 'user-789',
      uploaderName: 'User 789',
      profileImageUrl: null,
      isCover: false,
    ));
    photoIndex++;
  }

  final memory = MemoryEntity(
    id: 'memory-dynamic',
    eventId: 'event-dynamic',
    title: 'Memory Photos',
    location: 'Test Location',
    eventDate: _baseDate,
    photos: photos,
  );

  return memory;
}

// Removed unused _buildExpectedPattern function

// Removed unused _portraitPhoto and _landscapePhoto functions
