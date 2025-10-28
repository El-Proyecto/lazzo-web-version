import '../entities/memory_entity.dart';
import '../repositories/memory_repository.dart';

/// Use case: Get all photos from a memory ordered for viewer
/// - Covers first (ordered by votes descending)
/// - Then grid photos (ordered by timestamp ascending)
class GetMemoryPhotos {
  final MemoryRepository repository;

  const GetMemoryPhotos(this.repository);

  /// Returns ordered list of all photos for the viewer
  /// First covers (by votes), then grid (by timestamp)
  Future<List<MemoryPhoto>> call(String memoryId) async {
    final memory = await repository.getMemoryById(memoryId);
    if (memory == null) {
      throw Exception('Memory not found');
    }

    // Get covers (already sorted by votes in entity)
    final covers = memory.coverPhotos;

    // Get grid photos (already sorted by timestamp in entity)
    final grid = memory.gridPhotos;

    // Combine: covers first, then grid
    return [...covers, ...grid];
  }
}
