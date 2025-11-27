import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for group photos from Supabase
/// Handles all Supabase queries for photos
class GroupPhotosDataSource {
  final SupabaseClient _supabase;

  GroupPhotosDataSource(this._supabase);

  /// Helper to determine MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Get all photos for a specific event
  /// Returns photos ordered by captured_at descending
  Future<List<Map<String, dynamic>>> getEventPhotos(String eventId) async {
    try {
      final response = await _supabase
          .from('group_photos')
          .select('''
            id,
            url,
            storage_path,
            captured_at,
            uploader_id,
            is_portrait,
            profiles:uploader_id (
              name
            )
          ''')
          .eq('event_id', eventId)
          .order('captured_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch event photos: $e');
    }
  }

  /// Upload a photo to storage and create database record
  /// Returns the created photo data
  Future<Map<String, dynamic>> uploadPhoto({
    required String memoryId,
    required String groupId,
    required String filePath,
    required String fileName,
    required DateTime capturedAt,
    required bool isPortrait,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 1. Generate storage path: /{groupId}/{memoryId}/{userId}/{uuid}.jpg
      final uuid = DateTime.now().millisecondsSinceEpoch.toString();
      final extension = fileName.split('.').last;
      final storagePath = '$groupId/$memoryId/$userId/$uuid.$extension';

      // 2. Upload to storage
      final file = File(filePath);
      await _supabase.storage.from('memory_groups').upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              contentType: _getMimeType(extension),
              upsert: false,
            ),
          );

      // 3. Get public URL
      final url = _supabase.storage.from('group-photos').getPublicUrl(storagePath);

      // 4. Create database record
      final response = await _supabase
          .from('group_photos')
          .insert({
            'memory_id': memoryId,
            'url': url,
            'storage_path': storagePath,
            'captured_at': capturedAt.toIso8601String(),
            'uploader_id': userId,
            'is_portrait': isPortrait,
          })
          .select('''
            id,
            url,
            storage_path,
            captured_at,
            uploader_id,
            is_portrait,
            profiles:uploader_id (
              name
            )
          ''')
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Delete a photo (removes from storage and database)
  Future<void> deletePhoto(String photoId, String storagePath) async {
    try {
      // 1. Delete from storage
      await _supabase.storage.from('memory_groups').remove([storagePath]);

      // 2. Delete from database (cascade handled by ON DELETE)
      await _supabase.from('group_photos').delete().eq('id', photoId);
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  /// Get signed URL for authenticated access (for private bucket)
  Future<String> getSignedUrl(String storagePath, {int expiresIn = 3600}) async {
    try {
      return await _supabase.storage
          .from('memory_groups')
          .createSignedUrl(storagePath, expiresIn);
    } catch (e) {
      throw Exception('Failed to get signed URL: $e');
    }
  }
}
