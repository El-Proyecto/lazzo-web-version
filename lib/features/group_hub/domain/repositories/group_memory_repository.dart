import '../entities/group_memory_entity.dart';

/// Repository interface for group memories data access
abstract class GroupMemoryRepository {
  /// Get all memories for a specific group
  Future<List<GroupMemoryEntity>> getGroupMemories(String groupId);

  /// Get a single memory by ID
  Future<GroupMemoryEntity?> getMemoryById(String memoryId);
}
