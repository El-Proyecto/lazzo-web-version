// Trocar pelo fake
// FIXME: Rever

import '../../domain/entities/memory_summary.dart';
import '../../domain/repositories/memory_repository.dart';
import '../data_sources/memory_remote_data_source.dart';

class MemoryRepositoryImpl implements MemoryRepository {
  final MemoryRemoteDataSource remote; // injeta o datasource (Supabase)
  MemoryRepositoryImpl(this.remote);

  @override
  Future<MemorySummary?> getLastReadyMemory(String userId) async {
    final m = await remote.fetchLastReady(userId);
    return m?.toEntity();
  }
}
