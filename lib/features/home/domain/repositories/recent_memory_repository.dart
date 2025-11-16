import '../entities/recent_memory_entity.dart';

/// Repository interface for recent memories (last 30 days)
abstract class RecentMemoryRepository {
  /// Get recent memories from the last 30 days
  Future<List<RecentMemoryEntity>> getRecentMemories();
}
