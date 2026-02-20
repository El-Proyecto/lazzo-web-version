import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for fetching recent memories from the last 30 days
/// LAZZO 2.0: Rewritten to use event_participants instead of group_members
class RecentMemoryDataSource {
  final SupabaseClient _client;

  RecentMemoryDataSource(this._client);

  /// Fetch memories from the last 30 days for the current user
  /// Returns list of events with status 'recap' or 'ended' where user is a participant
  Future<List<Map<String, dynamic>>> getRecentMemories(String userId) async {
    try {
      // Calculate 30 days ago timestamp
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      print('[RecentMemory] userId=$userId thirtyDaysAgo=$thirtyDaysAgo');

      // 1) Get event IDs where user is a participant
      final participantResponse = await _client
          .from('event_participants')
          .select('pevent_id')
          .eq('user_id', userId);

      print('[RecentMemory] participantRows=${participantResponse.length}');

      if (participantResponse.isEmpty) {
        print('[RecentMemory] no participant rows → returning empty');
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
          .gte('end_datetime', thirtyDaysAgo.toIso8601String())
          .order('end_datetime', ascending: false);

      final eventsList = (eventsResponse as List).cast<Map<String, dynamic>>();
      print('[RecentMemory] eventsResponse count=${eventsList.length}');

      if (eventsList.isEmpty) {
        print(
            '[RecentMemory] eventsResponse is empty → check: statuses recap/ended AND end_datetime >= $thirtyDaysAgo');
        return [];
      }

      // 3) Process each event to add cover photo
      final List<Map<String, dynamic>> memoriesWithCovers = [];

      for (final event in eventsList) {
        final eventMap = Map<String, dynamic>.from(event);
        String? coverStoragePath;
        final eventId = eventMap['id'] as String;
        final coverPhotoId = eventMap['cover_photo_id'] as String?;

        // Try 1: Use cover_photo_id if set
        if (coverPhotoId != null) {
          try {
            final coverResponse = await _client
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
            final portraitResponse = await _client
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
            final anyPhoto = await _client
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

        print(
            '[RecentMemory] event=${eventMap['name']} coverStoragePath=$coverStoragePath');
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

      print('[RecentMemory] memoriesWithCovers=${memoriesWithCovers.length}');
      return memoriesWithCovers;
    } catch (e) {
      print('[RecentMemory] ERROR: $e');
      return [];
    }
  }
}
