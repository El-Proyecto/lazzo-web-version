// Removed unused import
import '../../domain/entities/memory_entity.dart';
import '../../domain/repositories/memory_repository.dart';

/// Global test configuration for cover mosaic scenarios
/// Modify these values to test different layouts
class FakeMemoryConfig {
  /// Number of portrait photos in covers (0-3)
  static int coverPortraitCount = 3;

  /// Number of landscape photos in covers (0-3)
  static int coverLandscapeCount = 0;

  /// Number of portrait photos in grid (non-covers)
  static int gridPortraitCount = 3;

  /// Number of landscape photos in grid (non-covers)
  static int gridLandscapeCount = 3;

  /// Whether current user is host (can select all photos)
  static bool isHost = false;

  /// Max covers is 3
  static int get totalCovers => coverPortraitCount + coverLandscapeCount;
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
}

final DateTime _baseDate = DateTime(2024, 7, 5);

/// Build memory from dynamic config
MemoryEntity _buildDynamicMemory() {
  final photos = <MemoryPhoto>[];
  var timestamp = _baseDate;
  var photoIndex = 1;

  // CRITICAL: Votes devem ser atribuídos na ordem EXATA que queremos os covers
  // Portraits devem ter votos MAIS ALTOS que landscapes para ficar em 1º após sort

  // Base votes: começam altos e decrescem
  final baseVotes = [100, 90, 80];

  // Criar lista de covers na ordem desejada (portraits primeiro)
  final coverTypes = <bool>[]; // true = portrait, false = landscape

  // Add portraits (serão os primeiros covers após sort por votos)
  for (var i = 0; i < FakeMemoryConfig.coverPortraitCount; i++) {
    coverTypes.add(true);
  }

  // Add landscapes (terão votos ligeiramente menores)
  for (var i = 0; i < FakeMemoryConfig.coverLandscapeCount; i++) {
    coverTypes.add(false);
  }

  // Criar fotos de cover com votos que garantem a ordem correta
  for (var i = 0; i < coverTypes.length; i++) {
    final isPortrait = coverTypes[i];
    final vote = baseVotes[i];

    if (isPortrait) {
      photos.add(MemoryPhoto(
        id: 'cover_p_$photoIndex',
        url: 'https://picsum.photos/seed/cover_p_$photoIndex/800/1000',
        thumbnailUrl:
            'https://picsum.photos/seed/cover_p_${photoIndex}_thumb/400/500',
        coverUrl:
            'https://picsum.photos/seed/cover_p_${photoIndex}_cover/1024/1280',
        voteCount: vote,
        capturedAt: timestamp,
        aspectRatio: 0.8,
        uploaderId: 'user-cover_p_$photoIndex',
        uploaderName: 'User cover_p_$photoIndex',
        isCover: true,
      ));
    } else {
      photos.add(MemoryPhoto(
        id: 'cover_l_$photoIndex',
        url: 'https://picsum.photos/seed/cover_l_$photoIndex/1600/900',
        thumbnailUrl:
            'https://picsum.photos/seed/cover_l_${photoIndex}_thumb/800/450',
        coverUrl:
            'https://picsum.photos/seed/cover_l_${photoIndex}_cover/1600/900',
        voteCount: vote,
        capturedAt: timestamp,
        aspectRatio: 16 / 9,
        uploaderId: 'user-cover_l_$photoIndex',
        uploaderName: 'User cover_l_$photoIndex',
        isCover: true,
      ));
    }

    timestamp = timestamp.add(const Duration(hours: 1));
    photoIndex++;
  }

  // Add grid photos (votos baixos para não interferir)
  // First 2 portrait photos belong to current user
  for (var i = 0; i < FakeMemoryConfig.gridPortraitCount; i++) {
    final isCurrentUser = i < 2; // First 2 are from current user
    photos.add(MemoryPhoto(
      id: 'grid_p_$photoIndex',
      url: 'https://picsum.photos/seed/grid_p_$photoIndex/800/1000',
      thumbnailUrl:
          'https://picsum.photos/seed/grid_p_${photoIndex}_thumb/400/500',
      coverUrl:
          'https://picsum.photos/seed/grid_p_${photoIndex}_cover/1024/1280',
      voteCount: 20 - i * 2,
      capturedAt: timestamp,
      aspectRatio: 0.8,
      uploaderId: isCurrentUser ? 'user-1' : 'user-grid_p_$photoIndex',
      uploaderName: isCurrentUser ? 'Current User' : 'User grid_p_$photoIndex',
      isCover: false,
    ));
    timestamp = timestamp.add(const Duration(hours: 1));
    photoIndex++;
  }

  // First 2 landscape photos belong to current user
  for (var i = 0; i < FakeMemoryConfig.gridLandscapeCount; i++) {
    final isCurrentUser = i < 2; // First 2 are from current user
    photos.add(MemoryPhoto(
      id: 'grid_l_$photoIndex',
      url: 'https://picsum.photos/seed/grid_l_$photoIndex/1600/900',
      thumbnailUrl:
          'https://picsum.photos/seed/grid_l_${photoIndex}_thumb/800/450',
      coverUrl:
          'https://picsum.photos/seed/grid_l_${photoIndex}_cover/1600/900',
      voteCount: 18 - i * 2,
      capturedAt: timestamp,
      aspectRatio: 16 / 9,
      uploaderId: isCurrentUser ? 'user-1' : 'user-grid_l_$photoIndex',
      uploaderName: isCurrentUser ? 'Current User' : 'User grid_l_$photoIndex',
      isCover: false,
    ));
    timestamp = timestamp.add(const Duration(hours: 1));
    photoIndex++;
  }

  final memory = MemoryEntity(
    id: 'memory-dynamic',
    eventId: 'event-dynamic',
    title:
        'Test: ${FakeMemoryConfig.coverPortraitCount}P + ${FakeMemoryConfig.coverLandscapeCount}L',
    location: 'Test Location',
    eventDate: _baseDate,
    photos: photos,
  );

  return memory;
}

// Removed unused _buildExpectedPattern function

// Removed unused _portraitPhoto and _landscapePhoto functions
