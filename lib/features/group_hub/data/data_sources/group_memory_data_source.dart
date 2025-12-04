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
    print('\n🔍 [MEMORIES DATA SOURCE] getGroupMemories called');
    print('   📍 Group ID: $groupId');
    try {
      // Query events with cover photo JOIN
      print('\n📡 [MEMORIES DATA SOURCE] Querying events table...');
      print('   🔎 Filter: group_id = $groupId (all statuses - will filter by photos later)');
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

      print('✅ [MEMORIES DATA SOURCE] Events query returned ${eventsResponse.length} results');
      if (eventsResponse.isEmpty) {
        print('ℹ️ [MEMORIES DATA SOURCE] No recap events found for this group');
        return [];
      }

      final events = List<Map<String, dynamic>>.from(eventsResponse);
      print('📝 [MEMORIES DATA SOURCE] First event: ${events.first}');
      
      // For each event, get cover photo or fallback to first photo
      for (int i = 0; i < events.length; i++) {
        final event = events[i];
        final eventId = event['id'] as String;
        final coverPhotoId = event['cover_photo_id'] as String?;
        
        print('\n🔄 [MEMORIES DATA SOURCE] Processing event ${i + 1}/${events.length}: $eventId');
        print('   📸 Cover photo ID: ${coverPhotoId ?? "null"}');
        
        // Get photo count for this event
        print('   🔢 Counting photos...');
        final photosResponse = await _client
            .from('group_photos')
            .select('id')
            .eq('event_id', eventId);
        
        event['photo_count'] = photosResponse.length;
        print('   ✅ Found ${photosResponse.length} photos');
        
        // Get cover photo
        String? coverStoragePath;
        
        if (coverPhotoId != null) {
          // Try to get the manually selected cover photo (user choice takes priority)
          print('   🔍 Fetching manually selected cover photo...');
          try {
            final coverPhoto = await _client
                .from('group_photos')
                .select('storage_path')
                .eq('id', coverPhotoId)
                .maybeSingle();
            
            if (coverPhoto != null) {
              coverStoragePath = coverPhoto['storage_path'] as String?;
              print('   ✅ Manual cover photo found: $coverStoragePath');
            } else {
              print('   ⚠️ Cover photo ID exists but photo not found in DB');
            }
          } catch (e) {
            print('   ⚠️ Cover photo not found: $coverPhotoId - $e');
          }
        }
        
        // Fallback to first PORTRAIT photo if no cover selected or cover not found
        if (coverStoragePath == null) {
          print('   🔄 No cover selected, searching for first PORTRAIT photo...');
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
              print('   ✅ First portrait photo found: $coverStoragePath');
            } else {
              print('   ℹ️ No portrait photos found, searching for ANY first photo...');
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
                  print('   ✅ First photo (any orientation) found: $coverStoragePath');
                } else {
                  print('   ℹ️ No photos found for this event - cover will be empty');
                }
              } catch (e) {
                print('   ⚠️ Error searching for any photo: $eventId - $e');
              }
            }
          } catch (e) {
            print('   ⚠️ Error searching for portrait photos: $eventId - $e');
          }
        }
        
        event['cover_storage_path'] = coverStoragePath;
        print('   📦 Final cover_storage_path: ${coverStoragePath ?? "null"}');
      }

      // Filter out memories with no photos
      final memoriesWithPhotos = events.where((event) {
        final photoCount = event['photo_count'] as int? ?? 0;
        return photoCount > 0;
      }).toList();
      
      print('\n✅ [MEMORIES DATA SOURCE] Successfully processed ${events.length} memories for group $groupId');
      print('   📸 Memories with photos: ${memoriesWithPhotos.length}/${events.length}');
      
      return memoriesWithPhotos;
    } catch (e, stackTrace) {
      print('❌ [MEMORIES DATA SOURCE] Error fetching group memories: $e');
      print('   Stack trace: $stackTrace');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getMemoryById(String memoryId) async {
    try {
      final response = await _client
          .from('events')
          .select('''
            id,
            name,
            start_datetime,
            location_id,
            emoji,
            status,
            locations:location_id(name)
          ''')
          .eq('id', memoryId)
          .eq('status', 'completed')
          .single();

      return response;
    } catch (e) {
      print('❌ Error fetching memory by ID: $e');
      return null;
    }
  }
}
