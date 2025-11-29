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
    print('\n🗄️ [MEMORIES REPOSITORY] getGroupMemories called for groupId: $groupId');
    try {
      print('📡 [MEMORIES REPOSITORY] Fetching from data source...');
      final jsonList = await _dataSource.getGroupMemories(groupId);
      print('✅ [MEMORIES REPOSITORY] Data source returned ${jsonList.length} items');
      
      if (jsonList.isEmpty) {
        print('ℹ️ [MEMORIES REPOSITORY] No memories found for this group');
        return [];
      }
      
      print('📝 [MEMORIES REPOSITORY] First raw JSON: ${jsonList.first}');
      
      // Convert to entities and generate signed URLs for covers
      final memories = <GroupMemoryEntity>[];
      for (int i = 0; i < jsonList.length; i++) {
        final json = jsonList[i];
        print('\n🔄 [MEMORIES REPOSITORY] Processing memory ${i + 1}/${jsonList.length}');
        final memory = GroupMemoryModel.fromJson(json);
        print('   - ID: ${memory.id}');
        print('   - Title: ${memory.title}');
        print('   - Cover storage path: ${memory.coverImageUrl}');
        print('   - Photo count: ${memory.photoCount}');
        
        // If memory has a cover storage path, generate signed URL
        if (memory.coverImageUrl.isNotEmpty) {
          try {
            print('   🔐 Generating signed URL for cover...');
            final signedUrl = await _storageService.getSignedUrl(
              memory.coverImageUrl, // This is storage_path from model
            );
            print('   ✅ Signed URL generated: ${signedUrl.substring(0, 50)}...');
            
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
            print('   ⚠️ Failed to generate signed URL for cover: $e');
            // Add memory without cover if URL generation fails
            memories.add(memory);
          }
        } else {
          print('   ℹ️ No cover photo, adding memory as-is');
          // No cover photo, add memory as-is
          memories.add(memory);
        }
      }
      
      print('\n✅ [MEMORIES REPOSITORY] Processed ${memories.length} memories successfully');
      return memories;
    } catch (e, stackTrace) {
      print('❌ [MEMORIES REPOSITORY] Error fetching group memories: $e');
      print('   Stack trace: $stackTrace');
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
    // } catch (e, stackTrace) {
    //   print('Error fetching memory by ID: $e');
    //   print(stackTrace);
    //   return null;
    // }

    throw UnimplementedError('P2: Implement getMemoryById repository method');
  }
}
