import 'package:lazzo/core/utils/date_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for memory operations with Supabase
///
/// Responsibilities:
/// - Query events table for memory (event in recap status)
/// - Query event_photos table for memory photos
/// - Update event cover_photo_id
class MemoryDataSource {
  final SupabaseClient _client;

  MemoryDataSource(this._client);

  /// Get memory by event ID (event in recap = memory)
  ///
  /// Query structure:
  /// SELECT events.*, locations.display_name
  /// FROM events
  /// LEFT JOIN locations ON events.location_id = locations.id
  /// WHERE events.id = eventId
  Future<Map<String, dynamic>?> getMemoryByEventId(String eventId) async {
    try {
      final response = await _client.from('events').select('''
            id,
            name,
            start_datetime,
            end_datetime,
            emoji,
            status,
            cover_photo_id,
            created_by,
            locations!location_id (
              display_name
            )
          ''').eq('id', eventId).maybeSingle();

      if (response == null) {
        return null;
      }

      return response;
    } on PostgrestException {
      return null;
    }
  }

  /// Get all photos for a memory (event)
  ///
  /// Query structure:
  /// SELECT event_photos.*, profiles.name
  /// FROM event_photos
  /// LEFT JOIN profiles ON event_photos.uploader_id = profiles.id
  /// WHERE event_id = eventId
  /// ORDER BY created_at ASC
  Future<List<Map<String, dynamic>>> getMemoryPhotos(String eventId) async {
    try {
      final response = await _client.from('event_photos').select('''
            id,
            storage_path,
            uploader_id,
            is_portrait,
            captured_at,
            created_at,
            users:uploader_id (
              name,
              avatar_url
            )
          ''').eq('event_id', eventId).order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException {
      return [];
    }
  }

  /// Update event cover photo
  ///
  /// photoId: UUID of the photo to set as cover (null to remove cover)
  Future<void> updateEventCover({
    required String eventId,
    String? photoId,
  }) async {
    try {
      await _client
          .from('events')
          .update({'cover_photo_id': photoId}).eq('id', eventId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update cover: ${e.message}');
    }
  }

  /// Close recap phase early (host only)
  /// Changes event status from 'recap' to 'ended'
  Future<void> closeRecapEarly(String eventId) async {
    try {
      final updated = await _client
          .from('events')
          .update({
            'status': 'ended',
            'updated_at': DateTime.now().toSupabaseIso8601String(),
          })
          .eq('id', eventId)
          .eq('status', 'recap')
          .select('id')
          .maybeSingle(); // Only update if currently in recap

      if (updated == null) {
        throw Exception('Failed to close recap: event is not in recap phase');
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to close recap: ${e.message}');
    }
  }
}
