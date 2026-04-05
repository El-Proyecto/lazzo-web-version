import '../entities/memory_entity.dart';

/// Repository interface for memory data
abstract class MemoryRepository {
  /// Get memory by ID
  Future<MemoryEntity?> getMemoryById(String memoryId);

  /// Get memory by event ID
  Future<MemoryEntity?> getMemoryByEventId(String eventId);

  /// Share memory (returns share URL or triggers native share)
  Future<String> shareMemory(String memoryId);

  /// Update cover photo for a memory
  /// Pass null photoId to remove cover
  Future<bool> updateCover(String memoryId, String? photoId);

  /// Remove a photo from a memory
  /// Only uploader or host can remove photos
  Future<bool> removePhoto(String memoryId, String photoId);

  /// Close recap phase early (host only)
  /// If photos exist and no cover is selected, first photo becomes cover.
  /// Returns true if recap was closed, false if operation fails.
  Future<bool> closeRecap(String eventId);
}
