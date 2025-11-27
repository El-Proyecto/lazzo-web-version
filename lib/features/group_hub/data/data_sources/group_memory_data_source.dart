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
    try {
      final response = await _client
          .from('events')
          .select('''
            id,
            name,
            start_datetime,
            location_id,
            emoji,
            status,
            locations:location_id(name)
          ''')
          .eq('group_id', groupId)
          .eq('status', 'completed')
          .order('start_datetime', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching group memories: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getMemoryById(String memoryId) async {
    try {
      final response = await _client
          .from('events')
          .select('''
            id,
            name,
            start_datetime,
            location_id,
            emoji,
            status,
            locations:location_id(name)
          ''')
          .eq('id', memoryId)
          .eq('status', 'completed')
          .single();

      return response;
    } catch (e) {
      print('❌ Error fetching memory by ID: $e');
      return null;
    }
  }
}
