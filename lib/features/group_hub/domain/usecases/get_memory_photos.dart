import '../entities/group_photo_entity.dart';
import '../repositories/group_photos_repository.dart';

/// Use case for getting photos from a specific memory/event
class GetMemoryPhotos {
  final GroupPhotosRepository repository;

  GetMemoryPhotos(this.repository);

  /// Get all photos for a memory/event
  /// Returns photos ordered by capturedAt descending
  Future<List<GroupPhotoEntity>> call(String memoryId) {
    return repository.getMemoryPhotos(memoryId);
  }
}
