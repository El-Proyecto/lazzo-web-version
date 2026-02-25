import '../../domain/entities/recent_memory_entity.dart';
import '../../domain/repositories/recent_memory_repository.dart';
import '../data_sources/recent_memory_data_source.dart';
import '../models/recent_memory_model.dart';
import '../../../../services/storage_service.dart';

/// Implementation of RecentMemoryRepository using Supabase
class RecentMemoryRepositoryImpl implements RecentMemoryRepository {
  final RecentMemoryDataSource _dataSource;
  final StorageService _storageService;
  final String _userId;

  RecentMemoryRepositoryImpl({
    required RecentMemoryDataSource dataSource,
    required StorageService storageService,
    required String userId,
  })  : _dataSource = dataSource,
        _storageService = storageService,
        _userId = userId;

  @override
  Future<List<RecentMemoryEntity>> getRecentMemories() async {
    try {
      // Fetch raw data from Supabase
      final jsonList = await _dataSource.getRecentMemories(_userId);

      if (jsonList.isEmpty) {
        return [];
      }

      // Convert to models
      final models =
          jsonList.map((json) => RecentMemoryModel.fromJson(json)).toList();

      // Generate signed URLs for cover photos (BATCH OPTIMIZED)
      final storagePaths = models
          .where((m) =>
              m.coverStoragePath != null && m.coverStoragePath!.isNotEmpty)
          .map((m) => m.coverStoragePath!)
          .toList();

      final signedUrlsMap = await _storageService.getBatchSignedUrls(
        storagePaths,
        bucket: 'memory_groups',
      );

      // Build entities with signed URLs
      final entities = models.map((model) {
        final coverPhotoUrl =
            model.coverStoragePath != null && model.coverStoragePath!.isNotEmpty
                ? signedUrlsMap[model.coverStoragePath]
                : null;

        return RecentMemoryEntity(
          id: model.id,
          eventName: model.eventName,
          location: model.location,
          date: model.date,
          coverPhotoUrl: coverPhotoUrl,
        );
      }).toList();

      return entities;
    } catch (e) {
            return [];
    }
  }
}
