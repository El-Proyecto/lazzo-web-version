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
      // Step 1: Upload to storage (returns storage path, not URL)
      // Storage path: groupId/eventId/userId/uuid.jpg
      final storagePath = await _storageService.uploadMemoryPhoto(
        groupId: groupId,
        memoryId: eventId,
        userId: userId,
        file: file,
      );

      // DEBUG: Verify RLS policy conditions before INSERT

      // Check 1: Verify event exists and has group_id
      try {
        final eventCheck = await _client
            .from('events')
            .select('id, group_id, created_by')
            .eq('id', eventId)
            .maybeSingle();

        if (eventCheck == null) {
          // Event not found
        } else {
          // Event found
        }
      } catch (e) {
        // Event check failed - RLS will handle authorization
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
          // User not member
        } else {
          // User is member
        }
      } catch (e) {
        // Member check failed - RLS will handle authorization
      }

      // Check 3: Verify uploader_id matches auth.uid()
      final currentUser = _client.auth.currentUser;
      if (currentUser?.id == userId) {
      } else {}

      // Step 2: Create database record
      // We store only the storage_path, not a URL
      // URLs are generated on-demand with createSignedUrl()
      final response = await _client
          .from('group_photos')
          .insert({
            'event_id': eventId,
            'uploader_id': userId,
            'url': storagePath, // Store path in 'url' field temporarily
            'storage_path': storagePath,
            'is_portrait': isPortrait,
            'captured_at': DateTime.now().toIso8601String(),
          })
          .select('id, storage_path')
          .single();

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
        return;
      }

      final storagePath = photoData['storage_path'] as String;

      // Delete from storage using the stored path
      await _client.storage.from('memory_groups').remove([storagePath]);

      // Delete from database
      await _client.from('group_photos').delete().eq('id', photoId);
    } catch (e) {
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
      rethrow;
    }
  }
}
