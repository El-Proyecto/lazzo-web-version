import '../repositories/memory_repository.dart';

/// Use case to share a memory
class ShareMemory {
  final MemoryRepository repository;

  const ShareMemory(this.repository);

  Future<String> call(String memoryId) {
    return repository.shareMemory(memoryId);
  }
}
