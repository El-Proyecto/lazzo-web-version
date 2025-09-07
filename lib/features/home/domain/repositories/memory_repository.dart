// contrato

import '../entities/memory_summary.dart';

abstract class MemoryRepository {
  Future<MemorySummary?> getLastReadyMemory(String userId);
}
