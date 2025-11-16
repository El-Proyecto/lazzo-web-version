import '../repositories/memory_repository.dart';

/// Use case for updating the cover photo of a memory
class UpdateMemoryCover {
  final MemoryRepository _repository;

  UpdateMemoryCover(this._repository);

  /// Updates the cover photo for a memory
  /// Returns true if successful
  Future<bool> call(String memoryId, String? photoId) async {
    return _repository.updateCover(memoryId, photoId);
  }
}
