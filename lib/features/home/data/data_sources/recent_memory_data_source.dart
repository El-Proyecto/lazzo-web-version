import 'package:lazzo/core/utils/date_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for fetching recent memories from the last 30 days
/// LAZZO 2.0: Rewritten to use event_participants instead of group_members
class RecentMemoryDataSource {
  final SupabaseClient _client;

  RecentMemoryDataSource(this._client);

  /// Fetch memories from the last 30 days for the current user
  /// Returns list of events with status 'recap' or 'ended' where user is a participant
  ///
  /// ✅ Optimized: single batch query for cover photos instead of N+1 individual queries.
  Future<List<Map<String, dynamic>>> getRecentMemories(String userId) async {
    try {
      // Calculate 30 days ago timestamp
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      // 1) Get event IDs where user is a participant
      final participantResponse = await _client
          .from('event_participants')
          .select('pevent_id')
          .eq('user_id', userId);

      
      if (participantResponse.isEmpty) {
                return [];
      }

      final eventIds =
          participantResponse.map((row) => row['pevent_id'] as String).toList();

      // 2) Query events with status 'recap' or 'ended' within 30 days
      final eventsResponse = await _client
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
          .gte('end_datetime', thirtyDaysAgo.toSupabaseIso8601String())
          .order('end_datetime', ascending: false);

      final eventsList = (eventsResponse as List).cast<Map<String, dynamic>>();
      
      if (eventsList.isEmpty) {
                return [];
      }

      // 3) ✅ BATCH: Fetch ALL photos for these events in ONE query
      //    Then pick the best cover photo per event in-memory.
      final memoryEventIds =
          eventsResponse.map((e) => e['id'] as String).toList();

      final allPhotos = await _client
          .from('event_photos')
          .select('id, event_id, storage_path, is_portrait')
          .inFilter('event_id', memoryEventIds)
          .order('captured_at', ascending: true);

      // Index photos by event_id for O(1) lookup
      final photosByEvent = <String, List<Map<String, dynamic>>>{};
      for (final photo in allPhotos as List) {
        final eid = photo['event_id'] as String;
        photosByEvent.putIfAbsent(eid, () => []).add(
          Map<String, dynamic>.from(photo),
        );
      }

      // 4) Pick best cover photo for each event
      final List<Map<String, dynamic>> memoriesWithCovers = [];

      for (final event in eventsList) {
        final eventMap = Map<String, dynamic>.from(event);
        final eventId = eventMap['id'] as String;
        final coverPhotoId = eventMap['cover_photo_id'] as String?;
        final photos = photosByEvent[eventId] ?? [];

        String? coverStoragePath;

        // Priority 1: explicit cover_photo_id
        if (coverPhotoId != null) {
          final match = photos.where((p) => p['id'] == coverPhotoId);
          if (match.isNotEmpty) {
            coverStoragePath = match.first['storage_path'] as String?;
          }
        }

        // Priority 2: first portrait photo
        if (coverStoragePath == null) {
          final portrait = photos.where((p) => p['is_portrait'] == true);
          if (portrait.isNotEmpty) {
            coverStoragePath = portrait.first['storage_path'] as String?;
          }
        }

        // Priority 3: any photo
        if (coverStoragePath == null && photos.isNotEmpty) {
          coverStoragePath = photos.first['storage_path'] as String?;
        }

                if (coverStoragePath != null) {
          memoriesWithCovers.add({
            'id': eventId,
            'name': eventMap['name'] as String? ?? 'Untitled',
            'end_datetime': eventMap['end_datetime'],
            'locations': eventMap['locations'],
            'cover_storage_path': coverStoragePath,
          });
        }
      }

            return memoriesWithCovers;
    } catch (e) {
            return [];
    }
  }
}
