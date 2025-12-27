// Data source for fetching user memories from Supabase events table

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileMemoryDataSource {
  final SupabaseClient client;

  ProfileMemoryDataSource(this.client);

  /// Fetch all memories (ended/recap events) for a user
  /// Returns events where user is a member, with cover photos (OPTIMIZED: single RPC query)
  Future<List<Map<String, dynamic>>> getUserMemories(String userId) async {
    try {
      // 1) Find all groups where user is a member
      final groupsResponse = await client
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      if (groupsResponse.isEmpty) {
        return [];
      }

      final groupIds =
          groupsResponse.map((row) => row['group_id'] as String).toList();

      // 2) Query events with RPC for automatic cover fallback (PHASE 2 OPTIMIZATION)
      // ✅ Single query with SQL-level fallback (replaces 30+ queries)
      final eventsResponse =
          await client.rpc('get_user_memories_with_covers', params: {
        'p_group_ids': groupIds,
      });

      // Filter out events without cover photos (safety check)
      final events = List<Map<String, dynamic>>.from(eventsResponse)
          .where((event) => event['cover_storage_path'] != null)
          .toList();

      return events;
    } catch (e) {
      rethrow;
    }
  }
}
