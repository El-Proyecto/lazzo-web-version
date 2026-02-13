// Data source for fetching user memories from Supabase events table
// LAZZO 2.0: Rewritten to use event_participants instead of group_members

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileMemoryDataSource {
  final SupabaseClient client;

  ProfileMemoryDataSource(this.client);

  /// Fetch all memories (ended/recap events) for a user
  /// Returns events where user is a participant, with cover photos
  Future<List<Map<String, dynamic>>> getUserMemories(String userId) async {
    try {
      // 1) Find all events where user is a participant
      final participantResponse = await client
          .from('event_participants')
          .select('pevent_id')
          .eq('user_id', userId);

      if (participantResponse.isEmpty) {
        return [];
      }

      final eventIds =
          participantResponse.map((row) => row['pevent_id'] as String).toList();

      // 2) Query events with status 'recap' or 'ended' and get cover photos
      final eventsResponse = await client
          .from('events')
          .select('''
            id,
            name,
            end_datetime,
            status,
            cover_photo_id,
            locations (
              display_name
            )
          ''')
          .inFilter('id', eventIds)
          .inFilter('status', ['recap', 'ended'])
          .order('end_datetime', ascending: false);

      if ((eventsResponse as List).isEmpty) {
        return [];
      }

      // 3) Process each event to add cover photo
      final List<Map<String, dynamic>> memoriesWithCovers = [];

      for (final event in eventsResponse) {
        final eventMap = Map<String, dynamic>.from(event);
        String? coverStoragePath;
        final eventId = eventMap['id'] as String;
        final coverPhotoId = eventMap['cover_photo_id'] as String?;

        // Try 1: Use cover_photo_id if set
        if (coverPhotoId != null) {
          try {
            final coverResponse = await client
                .from('event_photos')
                .select('storage_path')
                .eq('id', coverPhotoId)
                .maybeSingle();
            if (coverResponse != null) {
              coverStoragePath = coverResponse['storage_path'] as String?;
            }
          } catch (_) {}
        }

        // Try 2: Get first portrait photo
        if (coverStoragePath == null) {
          try {
            final portraitResponse = await client
                .from('event_photos')
                .select('storage_path')
                .eq('event_id', eventId)
                .eq('is_portrait', true)
                .order('captured_at', ascending: true)
                .limit(1)
                .maybeSingle();
            if (portraitResponse != null) {
              coverStoragePath = portraitResponse['storage_path'] as String?;
            }
          } catch (_) {}
        }

        // Try 3: Get any photo
        if (coverStoragePath == null) {
          try {
            final anyPhoto = await client
                .from('event_photos')
                .select('storage_path')
                .eq('event_id', eventId)
                .order('captured_at', ascending: true)
                .limit(1)
                .maybeSingle();
            if (anyPhoto != null) {
              coverStoragePath = anyPhoto['storage_path'] as String?;
            }
          } catch (_) {}
        }

        if (coverStoragePath != null) {
          memoriesWithCovers.add({
            'id': eventId,
            'title': eventMap['name'] as String? ?? 'Untitled',
            'date': eventMap['end_datetime'],
            'location':
                (eventMap['locations'] as Map?)?['display_name'] as String?,
            'cover_storage_path': coverStoragePath,
          });
        }
      }

      return memoriesWithCovers;
    } catch (e) {
      rethrow;
    }
  }
}
