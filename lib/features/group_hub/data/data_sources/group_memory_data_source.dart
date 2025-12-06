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
      // Query events with cover photo JOIN
      final eventsResponse = await _client
          .from('events')
          .select('''
            id,
            name,
            start_datetime,
            emoji,
            status,
            cover_photo_id,
            locations!location_id(display_name)
          ''')
          .eq('group_id', groupId)
          .order('start_datetime', ascending: false)
          .limit(50);

      if (eventsResponse.isEmpty) {
        return [];
      }

      final events = List<Map<String, dynamic>>.from(eventsResponse);

      // For each event, get cover photo or fallback to first photo
      for (int i = 0; i < events.length; i++) {
        final event = events[i];
        final eventId = event['id'] as String;
        final coverPhotoId = event['cover_photo_id'] as String?;

        // Get photo count for this event
        final photosResponse = await _client
            .from('group_photos')
            .select('id')
            .eq('event_id', eventId);

        event['photo_count'] = photosResponse.length;

        // Get cover photo
        String? coverStoragePath;

        if (coverPhotoId != null) {
          // Try to get the manually selected cover photo (user choice takes priority)
          try {
            final coverPhoto = await _client
                .from('group_photos')
                .select('storage_path')
                .eq('id', coverPhotoId)
                .maybeSingle();

            if (coverPhoto != null) {
              coverStoragePath = coverPhoto['storage_path'] as String?;
            } else {
              // Cover photo not selected
            }
          } catch (e) {
            // Failed to parse cover photo - continue with fallback
          }
        }

        // Fallback to first PORTRAIT photo if no cover selected or cover not found
        if (coverStoragePath == null) {
          try {
            final firstPortraitPhoto = await _client
                .from('group_photos')
                .select('storage_path')
                .eq('event_id', eventId)
                .eq('is_portrait', true)
                .order('created_at', ascending: true)
                .limit(1)
                .maybeSingle();

            if (firstPortraitPhoto != null) {
              coverStoragePath = firstPortraitPhoto['storage_path'] as String?;
            } else {
              // Final fallback: if no portrait photos, get any first photo
              try {
                final firstAnyPhoto = await _client
                    .from('group_photos')
                    .select('storage_path')
                    .eq('event_id', eventId)
                    .order('created_at', ascending: true)
                    .limit(1)
                    .maybeSingle();

                if (firstAnyPhoto != null) {
                  coverStoragePath = firstAnyPhoto['storage_path'] as String?;
                } else {
                  // No portrait photos found
                }
              } catch (e) {
                // Failed to parse portrait photo - continue without cover
              }
            }
          } catch (e) {
            // Failed to parse any photo - continue without cover
          }
        }

        event['cover_storage_path'] = coverStoragePath;
      }

      // Filter out memories with no photos
      final memoriesWithPhotos = events.where((event) {
        final photoCount = event['photo_count'] as int? ?? 0;
        return photoCount > 0;
      }).toList();

      return memoriesWithPhotos;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getMemoryById(String memoryId) async {
    try {
      final response = await _client.from('events').select('''
            id,
            name,
            start_datetime,
            location_id,
            emoji,
            status,
            locations:location_id(name)
          ''').eq('id', memoryId).eq('status', 'completed').single();

      return response;
    } catch (e) {
      return null;
    }
  }
}
