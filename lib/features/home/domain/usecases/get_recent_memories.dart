import '../entities/recent_memory_entity.dart';
import '../repositories/recent_memory_repository.dart';

/// Use case to get recent memories from the last 30 days
class GetRecentMemories {
  final RecentMemoryRepository repository;

  const GetRecentMemories(this.repository);

  Future<List<RecentMemoryEntity>> call() {
    return repository.getRecentMemories();
  }
}
