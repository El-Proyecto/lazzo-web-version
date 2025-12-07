import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for fetching recent memories from the last 30 days
class RecentMemoryDataSource {
  final SupabaseClient _client;

  RecentMemoryDataSource(this._client);

  /// Fetch memories from the last 30 days for the current user
  /// Returns list of events with status 'recap' or 'ended' from user's groups
  Future<List<Map<String, dynamic>>> getRecentMemories(String userId) async {
    try {
      // Get date 30 days ago
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      // Query events where:
      // 1. User is a member of the group
      // 2. Event status is 'recap' or 'ended' (completed events)
      // 3. Event end date is within last 30 days
      // 4. Order by end date descending (most recent first)
      final response = await _client
          .from('events')
          .select('''
            id,
            name,
            start_datetime,
            end_datetime,
            cover_photo_id,
            group_id,
            locations!location_id(display_name)
          ''')
          .gte('end_datetime', thirtyDaysAgo.toIso8601String())
          .inFilter('status', ['recap', 'ended'])
          .order('end_datetime', ascending: false)
          .limit(20);

      if (response.isEmpty) {
        return [];
      }

      final events = List<Map<String, dynamic>>.from(response);

      // Filter events where user is a group member
      final userGroupsResponse = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final userGroupIds = (userGroupsResponse as List)
          .map((m) => m['group_id'] as String)
          .toSet();

      final userEvents = events
          .where((event) => userGroupIds.contains(event['group_id']))
          .toList();

      // For each event, get cover photo if available
      for (final event in userEvents) {
        String? coverStoragePath;
        final coverPhotoId = event['cover_photo_id'] as String?;

        // Try 1: Use cover_photo_id if set
        if (coverPhotoId != null) {
          try {
            final photoResponse = await _client
                .from('group_photos')
                .select('storage_path')
                .eq('id', coverPhotoId)
                .maybeSingle();

            if (photoResponse != null) {
              coverStoragePath = photoResponse['storage_path'] as String?;
            }
          } catch (e) {
            // Cover photo not found, will try fallback
          }
        }

        // Try 2: Get first portrait photo if no cover set
        if (coverStoragePath == null) {
          try {
            final firstPhoto = await _client
                .from('group_photos')
                .select('storage_path')
                .eq('event_id', event['id'])
                .eq('is_portrait', true)
                .order('captured_at', ascending: true)
                .limit(1)
                .maybeSingle();

            if (firstPhoto != null) {
              coverStoragePath = firstPhoto['storage_path'] as String?;
            }
          } catch (e) {
            // No portrait photos found
          }
        }

        // Try 3: Get any photo if still no cover found
        if (coverStoragePath == null) {
          try {
            final anyPhoto = await _client
                .from('group_photos')
                .select('storage_path')
                .eq('event_id', event['id'])
                .order('captured_at', ascending: true)
                .limit(1)
                .maybeSingle();

            if (anyPhoto != null) {
              coverStoragePath = anyPhoto['storage_path'] as String?;
            }
          } catch (e) {
            // No photos found at all
          }
        }

        // Set the cover if we found one
        if (coverStoragePath != null) {
          event['cover_storage_path'] = coverStoragePath;
        }
      }

      return userEvents;
    } catch (e) {
      return [];
    }
  }
}
