import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for group memories from Supabase
/// 
/// P2 Implementation Requirements:
/// - Query 'group_memories' table with proper RLS policies
/// - Select only necessary columns (id, title, date, location, cover_photo_url, photo_count)
/// - Use indexes for performance (group_id, date DESC)
/// - Implement pagination with LIMIT/OFFSET for large datasets
abstract class GroupMemoryDataSource {
  /// Get all memories for a specific group
  /// 
  /// SQL Query Example:
  /// ```sql
  /// SELECT 
  ///   id, title, date, location, cover_photo_url, photo_count
  /// FROM group_memories
  /// WHERE group_id = ? AND deleted_at IS NULL
  /// ORDER BY date DESC
  /// LIMIT 50;
  /// ```
  Future<List<Map<String, dynamic>>> getGroupMemories(String groupId);

  /// Get a specific memory by ID
  /// 
  /// Returns memory data with all photo details
  Future<Map<String, dynamic>?> getMemoryById(String memoryId);
}

/// Supabase implementation of GroupMemoryDataSource
/// 
/// P2 TODO:
/// 1. Implement getGroupMemories() with proper filtering
/// 2. Implement getMemoryById() with photo details
/// 3. Add error handling for network failures
/// 4. Respect RLS policies (only group members can see memories)
/// 5. Use proper indexes for performance
class SupabaseGroupMemoryDataSource implements GroupMemoryDataSource {
  // ignore: unused_field
  final SupabaseClient _client;

  SupabaseGroupMemoryDataSource(this._client);

  @override
  Future<List<Map<String, dynamic>>> getGroupMemories(String groupId) async {
    // P2 TODO: Implement Supabase query
    // - Query group_memories table filtered by group_id
    // - Order by date DESC
    // - Handle errors and return empty list on failure
    throw UnimplementedError('P2: Implement Supabase query for group memories');
  }

  @override
  Future<Map<String, dynamic>?> getMemoryById(String memoryId) async {
    // P2 TODO: Implement single memory query
    // - Get memory by ID
    // - Include photo count and cover photo
    // - Return null if not found
    throw UnimplementedError('P2: Implement Supabase query for memory by ID');
  }
}
