import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for fetching recent memories from the last 30 days
class RecentMemoryDataSource {
  final SupabaseClient _client;

  RecentMemoryDataSource(this._client);

  /// Fetch memories from the last 30 days for the current user
  /// Returns list of events with status 'recap' or 'ended' from user's groups
  ///
  /// **OPTIMIZED VERSION**: Uses SQL RPC function to eliminate N+1 queries.
  /// Replaces 20+ sequential queries with a single database call.
  ///
  /// Requires P2 team to deploy `get_recent_memories_with_covers` RPC function.
  /// See IMPLEMENTATION/SQL_FUNCTIONS_FOR_P2.md for deployment guide.
  Future<List<Map<String, dynamic>>> getRecentMemories(String userId) async {
    try {
      // Calculate 30 days ago timestamp
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      // 1) Get user's group IDs
      final groupsResponse = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      if (groupsResponse.isEmpty) {
        return [];
      }

      final groupIds =
          groupsResponse.map((row) => row['group_id'] as String).toList();

      // 2) Call RPC function that handles:
      // - Filter events from user's groups
      // - Find events with status 'recap' or 'ended'
      // - Apply 30-day time window
      // - Use COALESCE to get best available cover photo
      final response = await _client.rpc(
        'get_recent_memories_with_covers',
        params: {
          'p_user_group_ids': groupIds,
          'p_start_date': thirtyDaysAgo.toIso8601String(),
        },
      );

      if (response == null || response is! List) {
        return [];
      }

      // Filter out events without cover photos (safety check)
      final events = List<Map<String, dynamic>>.from(response)
          .where((event) => event['cover_storage_path'] != null)
          .toList();

      return events;
    } catch (e) {
      // RPC function not available or query failed
      return [];
    }
  }
}
