import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for memory operations with Supabase
/// 
/// Responsibilities:
/// - Query events table for memory (event in recap status)
/// - Query group_photos table for memory photos
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
      final response = await _client
          .from('events')
          .select('''
            id,
            name,
            start_datetime,
            end_datetime,
            emoji,
            status,
            cover_photo_id,
            group_id,
            locations!location_id (
              display_name
            )
          ''')
          .eq('id', eventId)
          .maybeSingle();

      if (response == null) {
        print('⚠️ Memory not found for eventId: $eventId');
        return null;
      }

      print('✅ Memory found: ${response['name']}');
      return response;
    } on PostgrestException catch (e) {
      print('❌ Failed to get memory: ${e.message}');
      return null;
    }
  }

  /// Get all photos for a memory (event)
  /// 
  /// Query structure:
  /// SELECT group_photos.*, profiles.name
  /// FROM group_photos
  /// LEFT JOIN profiles ON group_photos.uploader_id = profiles.id
  /// WHERE event_id = eventId
  /// ORDER BY created_at ASC
  Future<List<Map<String, dynamic>>> getMemoryPhotos(String eventId) async {
    try {
      final response = await _client
          .from('group_photos')
          .select('''
            id,
            storage_path,
            uploader_id,
            is_portrait,
            captured_at,
            created_at,
            profiles:uploader_id (
              name
            )
          ''')
          .eq('event_id', eventId)
          .order('created_at', ascending: true);

      print('✅ Found ${response.length} photos for memory');
      print('📋 [MEMORY DATA SOURCE] Sample photo data:');
      if (response.isNotEmpty) {
        final sample = response.first;
        print('   - uploader_id: ${sample['uploader_id']}');
        print('   - profiles: ${sample['profiles']}');
      }
      
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      print('❌ Failed to get memory photos: ${e.message}');
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
          .update({'cover_photo_id': photoId})
          .eq('id', eventId);

      print('✅ Cover updated: eventId=$eventId, photoId=$photoId');
    } on PostgrestException catch (e) {
      print('❌ Failed to update cover: ${e.message}');
      throw Exception('Failed to update cover: ${e.message}');
    }
  }
}
