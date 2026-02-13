import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for fetching other user profiles and shared data from Supabase
/// LAZZO 2.0: Rewritten to use event_participants instead of group_members
class OtherProfileDataSource {
  final SupabaseClient _client;

  OtherProfileDataSource(this._client);

  /// Get other user's profile information from users table
  /// Returns raw profile data including avatar_url
  Future<Map<String, dynamic>> getOtherUserProfile(String userId) async {
    final response = await _client
        .from('users')
        .select('id, name, avatar_url, city, birth_date')
        .eq('id', userId)
        .single();

    return response;
  }

  /// Get shared memories between current user and target user
  /// Logic:
  /// 1. Find all events where current user is a participant
  /// 2. Find events where target user is also a participant (intersection)
  /// 3. Return events with status='recap'/'ended' with cover photos
  Future<List<Map<String, dynamic>>> getSharedMemories({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      // Step 1: Get events where current user is a participant
      final currentUserEvents = await _client
          .from('event_participants')
          .select('pevent_id')
          .eq('user_id', currentUserId);

      if ((currentUserEvents as List).isEmpty) {
        return [];
      }

      final currentEventIds =
          currentUserEvents.map((e) => e['pevent_id'] as String).toList();

      // Step 2: Get events where target user is also a participant (intersection)
      final targetUserEvents = await _client
          .from('event_participants')
          .select('pevent_id')
          .eq('user_id', targetUserId)
          .inFilter('pevent_id', currentEventIds);

      final sharedEventIds = (targetUserEvents as List)
          .map((e) => e['pevent_id'] as String)
          .toList();

      if (sharedEventIds.isEmpty) {
        return [];
      }

      // Step 3: Query events with status 'recap' or 'ended'
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
          .inFilter('id', sharedEventIds)
          .inFilter('status', ['recap', 'ended'])
          .order('end_datetime', ascending: false);

      if ((eventsResponse as List).isEmpty) {
        return [];
      }

      // Step 4: Process each event to add cover photo
      final List<Map<String, dynamic>> memoriesWithCovers = [];

      for (final event in eventsResponse) {
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

        // Only add event if we found a valid cover photo
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

  /// Get upcoming events shared between two users
  /// Returns events with status='confirmed' or 'living' where both are participants
  Future<List<Map<String, dynamic>>> getSharedUpcomingEvents({
    required String currentUserId,
    required String targetUserId,
  }) async {
    // Get events where current user is a participant
    final currentUserEvents = await _client
        .from('event_participants')
        .select('pevent_id')
        .eq('user_id', currentUserId);

    final currentEventIds = (currentUserEvents as List)
        .map((e) => e['pevent_id'] as String)
        .toSet();

    if (currentEventIds.isEmpty) {
      return [];
    }

    // Get events where target user is also a participant (intersection)
    final targetUserEvents = await _client
        .from('event_participants')
        .select('pevent_id')
        .eq('user_id', targetUserId)
        .inFilter('pevent_id', currentEventIds.toList());

    final sharedEventIds = (targetUserEvents as List)
        .map((e) => e['pevent_id'] as String)
        .toList();

    if (sharedEventIds.isEmpty) {
      return [];
    }

    // Get confirmed/living events
    final events = await _client
        .from('events')
        .select(
            'id, name, emoji, start_datetime, end_datetime, status, locations(display_name)')
        .inFilter('id', sharedEventIds)
        .inFilter('status', ['confirmed', 'living'])
        .gte('start_datetime', DateTime.now().toIso8601String())
        .order('start_datetime', ascending: true)
        .limit(20);

    return (events as List).cast<Map<String, dynamic>>();
  }
}
