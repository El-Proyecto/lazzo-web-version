//caso de uso

import '../entities/memory_summary.dart';
import '../repositories/memory_repository.dart';

class GetLastMemory {
  final MemoryRepository repo;
  GetLastMemory(this.repo);
  Future<MemorySummary?> call(String userId) => repo.getLastReadyMemory(userId);
}
