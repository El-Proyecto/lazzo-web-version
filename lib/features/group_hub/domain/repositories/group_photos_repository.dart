import '../entities/group_photo_entity.dart';

/// Repository interface for group photos
/// Photos are always associated with events/memories
abstract class GroupPhotosRepository {
  /// Get all photos for a group (from all events)
  /// Returns list of photos ordered by capturedAt desc
  /// These photos are stored in the 'memory_groups' bucket
  Future<List<GroupPhotoEntity>> getGroupPhotos(String groupId);
}
