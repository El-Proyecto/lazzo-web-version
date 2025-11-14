import '../entities/group_photo_entity.dart';

/// Repository interface for group photos
/// Photos are always associated with events/memories
abstract class GroupPhotosRepository {
  /// Get all photos for a specific memory/event
  /// Returns list of photos ordered by capturedAt desc
  Future<List<GroupPhotoEntity>> getMemoryPhotos(String memoryId);
}
