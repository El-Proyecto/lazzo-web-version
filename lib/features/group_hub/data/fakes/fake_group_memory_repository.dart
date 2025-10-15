import '../../domain/entities/group_memory_entity.dart';
import '../../domain/repositories/group_memory_repository.dart';

/// Fake implementation of GroupMemoryRepository for development
class FakeGroupMemoryRepository implements GroupMemoryRepository {
  final List<GroupMemoryEntity> _memories = [];

  @override
  Future<List<GroupMemoryEntity>> getGroupMemories(String groupId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _memories; // Empty list for now
  }

  @override
  Future<GroupMemoryEntity?> getMemoryById(String memoryId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _memories.firstWhere((memory) => memory.id == memoryId);
    } catch (e) {
      return null;
    }
  }
}
