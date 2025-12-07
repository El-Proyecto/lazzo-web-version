// Data source for fetching user memories from Supabase events table

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileMemoryDataSource {
  final SupabaseClient client;

  ProfileMemoryDataSource(this.client);

  /// Fetch all memories (ended/recap events) for a user
  /// Returns events where user is a member, with cover photos
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

      final groupIds = groupsResponse
          .map((row) => row['group_id'] as String)
          .toList();

      // 2) Query events for those groups with status 'recap' or 'ended'
      final eventsResponse = await client
          .from('events')
          .select('''
            id,
            name,
            end_datetime,
            locations (
              display_name
            ),
            cover_photo_id
          ''')
          .inFilter('group_id', groupIds)
          .inFilter('status', ['recap', 'ended'])
          .order('end_datetime', ascending: false);

      if (eventsResponse.isEmpty) {
        return [];
      }

      // 3) Process each event to add cover photo
      final List<Map<String, dynamic>> memoriesWithCovers = [];
      
      for (final event in eventsResponse) {
        final eventMap = Map<String, dynamic>.from(event);
        String? coverStoragePath;

        final eventId = eventMap['id'] as String;
        final coverPhotoId = eventMap['cover_photo_id'] as String?;

        // Try to get cover photo using cover_photo_id first
        if (coverPhotoId != null) {
          final coverResponse = await client
              .from('group_photos')
              .select('storage_path')
              .eq('id', coverPhotoId)
              .maybeSingle();

          if (coverResponse != null) {
            coverStoragePath = coverResponse['storage_path'] as String?;
          }
        }

        // Fallback: get first portrait photo if no cover_photo_id
        if (coverStoragePath == null) {
          final portraitResponse = await client
              .from('group_photos')
              .select('storage_path')
              .eq('event_id', eventId)
              .eq('is_portrait', true)
              .order('uploaded_at', ascending: true)
              .limit(1)
              .maybeSingle();

          if (portraitResponse != null) {
            coverStoragePath = portraitResponse['storage_path'] as String?;
          }
        }

        // Add cover storage path to event data
        eventMap['cover_storage_path'] = coverStoragePath;
        memoriesWithCovers.add(eventMap);
      }

      return memoriesWithCovers;
    } catch (e) {
      rethrow;
    }
  }
}
