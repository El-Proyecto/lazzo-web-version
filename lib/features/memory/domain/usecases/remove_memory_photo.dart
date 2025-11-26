import '../repositories/memory_repository.dart';

/// Use case for removing a photo from a memory
class RemoveMemoryPhoto {
  final MemoryRepository _repository;

  RemoveMemoryPhoto(this._repository);

  /// Removes a photo from a memory
  /// Only the uploader or event host can remove photos
  Future<bool> call(String memoryId, String photoId) async {
    return _repository.removePhoto(memoryId, photoId);
  }
}
