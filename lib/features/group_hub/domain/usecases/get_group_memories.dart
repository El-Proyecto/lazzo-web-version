import '../entities/group_memory_entity.dart';
import '../repositories/group_memory_repository.dart';

/// Use case for getting group memories
class GetGroupMemories {
  final GroupMemoryRepository _repository;

  GetGroupMemories(this._repository);

  Future<List<GroupMemoryEntity>> call(String groupId) async {
            final result = await _repository.getGroupMemories(groupId);
        return result;
  }
}
