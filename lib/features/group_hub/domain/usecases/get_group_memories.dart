import '../entities/group_memory_entity.dart';
import '../repositories/group_memory_repository.dart';

/// Use case for getting group memories
class GetGroupMemories {
  final GroupMemoryRepository _repository;

  GetGroupMemories(this._repository);

  Future<List<GroupMemoryEntity>> call(String groupId) async {
    print('\n📦 [MEMORIES USE CASE] Called with groupId: $groupId');
    print('🔗 [MEMORIES USE CASE] Repository: ${_repository.runtimeType}');
    final result = await _repository.getGroupMemories(groupId);
    print('✅ [MEMORIES USE CASE] Repository returned ${result.length} memories');
    return result;
  }
}
