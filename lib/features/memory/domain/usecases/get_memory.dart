import '../entities/memory_entity.dart';
import '../repositories/memory_repository.dart';

/// Use case to fetch a memory by ID
class GetMemory {
  final MemoryRepository repository;

  const GetMemory(this.repository);

  Future<MemoryEntity?> call(String memoryId) {
    return repository.getMemoryById(memoryId);
  }
}
