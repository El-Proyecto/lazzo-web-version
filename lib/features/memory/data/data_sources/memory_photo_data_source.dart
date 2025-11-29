import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/storage_service.dart';

/// Data source for memory photo operations using Supabase
class MemoryPhotoDataSource {
  final SupabaseClient _client;
  final StorageService _storageService;

  MemoryPhotoDataSource(this._client)
      : _storageService = StorageService(_client);

  /// Upload a photo and create a record in group_photos table
  /// 
  /// Steps:
  /// 1. Upload file to storage (memory_groups PRIVATE bucket)
  /// 2. Insert record in group_photos table with storage_path
  /// 
  /// Returns the photo ID and storage_path
  /// Note: URLs are generated on-demand using signed URLs with RLS validation
  Future<Map<String, dynamic>> uploadPhoto({
    required String groupId,
    required String eventId,
    required String userId,
    required File file,
    required bool isPortrait,
  }) async {
    try {
      print('📸 Starting photo upload...');
      print('   - groupId: $groupId');
      print('   - eventId: $eventId');
      print('   - userId: $userId');
      
      // Step 1: Upload to storage (returns storage path, not URL)
      // Storage path: groupId/eventId/userId/uuid.jpg
      final storagePath = await _storageService.uploadMemoryPhoto(
        groupId: groupId,
        memoryId: eventId,
        userId: userId,
        file: file,
      );
      
      print('📍 Storage path: $storagePath');
      
      // DEBUG: Verify RLS policy conditions before INSERT
      print('🔍 DEBUG: Checking RLS policy conditions...');
      
      // Check 1: Verify event exists and has group_id
      try {
        final eventCheck = await _client
            .from('events')
            .select('id, group_id, created_by')
            .eq('id', eventId)
            .maybeSingle();
        
        if (eventCheck == null) {
          print('❌ Event not found: $eventId');
        } else {
          print('✅ Event exists: ${eventCheck['id']}');
          print('   - group_id: ${eventCheck['group_id']}');
          print('   - created_by: ${eventCheck['created_by']}');
        }
      } catch (e) {
        print('❌ Failed to check event: $e');
      }
      
      // Check 2: Verify user is member of the group
      try {
        final memberCheck = await _client
            .from('group_members')
            .select('user_id, group_id, role')
            .eq('user_id', userId)
            .eq('group_id', groupId)
            .maybeSingle();
        
        if (memberCheck == null) {
          print('❌ User is NOT a member of group $groupId');
        } else {
          print('✅ User is member of group');
          print('   - user_id: ${memberCheck['user_id']}');
          print('   - group_id: ${memberCheck['group_id']}');
          print('   - role: ${memberCheck['role']}');
        }
      } catch (e) {
        print('❌ Failed to check membership: $e');
      }
      
      // Check 3: Verify uploader_id matches auth.uid()
      final currentUser = _client.auth.currentUser;
      if (currentUser?.id == userId) {
        print('✅ uploader_id matches auth.uid(): $userId');
      } else {
        print('❌ uploader_id MISMATCH!');
        print('   - Expected (userId param): $userId');
        print('   - Actual (auth.uid()): ${currentUser?.id}');
      }
      
      print('🔍 DEBUG: All checks complete. Attempting INSERT...');
      
      // Step 2: Create database record
      // We store only the storage_path, not a URL
      // URLs are generated on-demand with createSignedUrl()
      final response = await _client.from('group_photos').insert({
        'event_id': eventId,
        'uploader_id': userId,
        'url': storagePath, // Store path in 'url' field temporarily
        'storage_path': storagePath,
        'is_portrait': isPortrait,
        'captured_at': DateTime.now().toIso8601String(),
      }).select('id, storage_path').single();
      
      print('✅ Photo record created in DB: ${response['id']}');
      
      // Don't generate signed URL immediately - let it be generated on-demand
      // This avoids RLS propagation delays after upload
      // The UI will request signed URLs when needed via getSignedUrl()
      
      // Return ID and storage path (URL will be generated later)
      return {
        'id': response['id'],
        'url': storagePath, // Return path for now, UI will generate signed URL
        'storage_path': storagePath,
      };
    } catch (e) {
      print('❌ Failed to upload photo: $e');
      rethrow;
    }
  }

  /// Delete a photo (both storage and database record)
  /// 
  /// photoId: UUID of the photo record in group_photos table
  Future<void> deletePhoto(String photoId) async {
    try {
      // First get the storage_path from the database
      final photoData = await _client
          .from('group_photos')
          .select('storage_path')
          .eq('id', photoId)
          .maybeSingle();
      
      if (photoData == null) {
        print('⚠️ Photo not found in database: $photoId');
        return;
      }
      
      final storagePath = photoData['storage_path'] as String;
      
      // Delete from storage using the stored path
      await _client.storage
          .from('memory_groups')
          .remove([storagePath]);
      
      // Delete from database
      await _client.from('group_photos').delete().eq('id', photoId);
      
      print('✅ Photo deleted successfully: $photoId');
    } catch (e) {
      print('❌ Failed to delete photo: $e');
      rethrow;
    }
  }

  /// Get all photos for an event
  Future<List<Map<String, dynamic>>> getPhotosForEvent(String eventId) async {
    try {
      final response = await _client
          .from('group_photos')
          .select('id, url, is_portrait, uploader_id, captured_at, created_at')
          .eq('event_id', eventId)
          .order('captured_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Failed to fetch photos: $e');
      rethrow;
    }
  }
}
