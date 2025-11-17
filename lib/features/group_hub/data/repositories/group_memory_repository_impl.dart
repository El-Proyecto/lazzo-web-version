import '../../domain/entities/group_memory_entity.dart';
import '../../domain/repositories/group_memory_repository.dart';
import '../data_sources/group_memory_data_source.dart';

/// Supabase implementation of GroupMemoryRepository
/// 
/// P2 Implementation Requirements:
/// - Use GroupMemoryDataSource to fetch data from Supabase
/// - Convert raw JSON to entities using GroupMemoryModel
/// - Handle errors and return empty lists/null gracefully
/// - Add logging for debugging
class GroupMemoryRepositoryImpl implements GroupMemoryRepository {
  // ignore: unused_field
  final GroupMemoryDataSource _dataSource;

  GroupMemoryRepositoryImpl(this._dataSource);

  @override
  Future<List<GroupMemoryEntity>> getGroupMemories(String groupId) async {
    // P2 TODO: Implement repository method
    // 
    // Implementation steps:
    // 1. Call _dataSource.getGroupMemories(groupId)
    // 2. Convert each JSON map to GroupMemoryEntity using GroupMemoryModel.fromJson()
    // 3. Handle errors (catch exceptions, log, return empty list)
    // 4. Return list of entities
    //
    // Example implementation:
    // try {
    //   final jsonList = await _dataSource.getGroupMemories(groupId);
    //   return jsonList
    //       .map((json) => GroupMemoryModel.fromJson(json))
    //       .toList();
    // } catch (e, stackTrace) {
    //   print('Error fetching group memories: $e');
    //   print(stackTrace);
    //   return [];
    // }

    throw UnimplementedError('P2: Implement getGroupMemories repository method');
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
