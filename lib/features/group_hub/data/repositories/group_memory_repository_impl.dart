import '../../domain/entities/group_memory_entity.dart';
import '../../domain/repositories/group_memory_repository.dart';
import '../data_sources/group_memory_data_source.dart';
import '../models/group_memory_model.dart';
import '../../../../services/storage_service.dart';

/// Supabase implementation of GroupMemoryRepository
/// 
/// P2 Implementation Requirements:
/// - Use GroupMemoryDataSource to fetch data from Supabase
/// - Convert raw JSON to entities using GroupMemoryModel
/// - Generate signed URLs for cover photos
/// - Handle errors and return empty lists/null gracefully
/// - Add logging for debugging
class GroupMemoryRepositoryImpl implements GroupMemoryRepository {
  final GroupMemoryDataSource _dataSource;
  final StorageService _storageService;

  GroupMemoryRepositoryImpl(this._dataSource, this._storageService);

  @override
  Future<List<GroupMemoryEntity>> getGroupMemories(String groupId) async {
    try {
      final jsonList = await _dataSource.getGroupMemories(groupId);
      
      if (jsonList.isEmpty) {
        return [];
      }
      
      // Convert to entities and generate signed URLs for covers
      final memories = <GroupMemoryEntity>[];
      for (int i = 0; i < jsonList.length; i++) {
        final json = jsonList[i];
        final memory = GroupMemoryModel.fromJson(json);
        
        // If memory has a cover storage path, generate signed URL
        if (memory.coverImageUrl.isNotEmpty && memory.coverImageUrl != 'placeholder') {
          try {
            final signedUrl = await _storageService.getSignedUrl(
              memory.coverImageUrl, // This is storage_path from model
            );
            
            // Create new entity with signed URL
            memories.add(GroupMemoryEntity(
              id: memory.id,
              title: memory.title,
              date: memory.date,
              location: memory.location,
              coverImageUrl: signedUrl, // Replace storage_path with signed URL
              photoCount: memory.photoCount,
            ));
          } catch (e) {
            // Add memory without cover (null URL)
            memories.add(GroupMemoryEntity(
              id: memory.id,
              title: memory.title,
              date: memory.date,
              location: memory.location,
              coverImageUrl: 'placeholder', // Use placeholder to prevent NetworkImage error
              photoCount: memory.photoCount,
            ));
          }
        } else {
          // No cover photo, ensure we use placeholder instead of empty string
          memories.add(GroupMemoryEntity(
            id: memory.id,
            title: memory.title,
            date: memory.date,
            location: memory.location,
            coverImageUrl: 'placeholder', // Placeholder to prevent NetworkImage error
            photoCount: memory.photoCount,
          ));
        }
      }
      
      return memories;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<GroupMemoryEntity?> getMemoryById(String memoryId) async {
    // P2 TODO: Implement repository method
    // 
    // Implementation steps:
    // 1. Call _dataSource.getMemoryById(memoryId)
    // 2. If null, return null
    // 3. Convert JSON to GroupMemoryEntity using GroupMemoryModel.fromJson()
    // 4. Handle errors (catch exceptions, log, return null)
    // 5. Return entity or null
    //
    // Example implementation:
    // try {
    //   final json = await _dataSource.getMemoryById(memoryId);
    //   if (json == null) return null;
    //   return GroupMemoryModel.fromJson(json);
    // } catch (e) {
    //       //       //   return null;
    // }

    throw UnimplementedError('P2: Implement getMemoryById repository method');
  }
}
