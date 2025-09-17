import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

/// Use case for getting user memories
class GetUserMemories {
  final ProfileRepository _repository;

  const GetUserMemories(this._repository);

  Future<List<MemoryEntity>> call(String userId) async {
    return await _repository.getUserMemories(userId);
  }
}
