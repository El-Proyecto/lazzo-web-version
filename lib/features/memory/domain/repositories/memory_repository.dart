import '../entities/memory_entity.dart';

/// Repository interface for memory data
abstract class MemoryRepository {
  /// Get memory by ID
  Future<MemoryEntity?> getMemoryById(String memoryId);

  /// Get memory by event ID
  Future<MemoryEntity?> getMemoryByEventId(String eventId);

  /// Share memory (returns share URL or triggers native share)
  Future<String> shareMemory(String memoryId);
}
