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

      // Convert to models and then to entities with signed URLs
      final entities = <RecentMemoryEntity>[];

      for (final json in jsonList) {
        final model = RecentMemoryModel.fromJson(json);

        // Generate signed URL for cover photo if available
        String? coverPhotoUrl;
        if (model.coverStoragePath != null &&
            model.coverStoragePath!.isNotEmpty) {
          try {
            coverPhotoUrl = await _storageService.getSignedUrl(
              model.coverStoragePath!,
            );
          } catch (e) {
            // Failed to generate signed URL, continue without cover
          }
        }

        entities.add(RecentMemoryEntity(
          id: model.id,
          eventName: model.eventName,
          location: model.location,
          date: model.date,
          coverPhotoUrl: coverPhotoUrl,
        ));
      }

      return entities;
    } catch (e) {
      return [];
    }
  }
}
