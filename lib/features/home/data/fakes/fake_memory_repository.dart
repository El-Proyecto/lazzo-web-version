import '../../domain/entities/memory_summary.dart';
import '../../domain/repositories/memory_repository.dart';

class FakeMemoryRepository implements MemoryRepository {
  @override
  Future<MemorySummary?> getLastReadyMemory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MemorySummary(
      eventId: 'mem_1',
      title: 'Pescaria',
      emoji: '🐟',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
  }
}
