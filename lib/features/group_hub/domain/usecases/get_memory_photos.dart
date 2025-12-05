import '../entities/group_photo_entity.dart';
import '../repositories/group_photos_repository.dart';

/// Use case for getting photos from a group (all events)
class GetGroupPhotos {
  final GroupPhotosRepository repository;

  GetGroupPhotos(this.repository);

  /// Get all photos for a group (from all events)
  /// Returns photos ordered by capturedAt descending
  Future<List<GroupPhotoEntity>> call(String groupId) {
    return repository.getGroupPhotos(groupId);
  }
}
