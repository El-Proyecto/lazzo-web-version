import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for event photo operations using Supabase
/// Handles photo uploads to memory_groups storage bucket
class EventPhotoDataSource {
  final SupabaseClient _client;

  EventPhotoDataSource(this._client);

  /// Upload a photo to Supabase Storage and create database record
  /// 
  /// Storage path: /{groupId}/{eventId}/{userId}/{timestamp}.jpg
  /// Bucket: memory_groups (private, requires auth)
  /// 
  /// Returns the uploaded photo data including URL and storage path
  Future<Map<String, dynamic>> uploadPhoto({
    required String eventId,
    required String groupId,
    required File imageFile,
    required DateTime capturedAt,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 1. Generate storage path: /{groupId}/{eventId}/{userId}/{timestamp}.extension
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last.toLowerCase();
      final storagePath = '$groupId/$eventId/$userId/$timestamp.$extension';

      print('📤 Uploading photo to: $storagePath');

      // 2. Upload to Supabase Storage
      final uploadPath = await _client.storage
          .from('memory_groups')
          .upload(
            storagePath,
            imageFile,
            fileOptions: FileOptions(
              contentType: _getMimeType(extension),
              upsert: false,
            ),
          );

      print('✅ Photo uploaded to storage: $uploadPath');

      // 3. Get public URL (will require signed URL for private bucket)
      final publicUrl = _client.storage
          .from('memory_groups')
          .getPublicUrl(storagePath);

      print('🔗 Public URL: $publicUrl');

      // 4. Create database record in group_photos table
      final photoData = {
        'event_id': eventId,
        'url': publicUrl,
        'storage_path': storagePath,
        'captured_at': capturedAt.toIso8601String(),
        'uploader_id': userId,
        'is_portrait': await _isPortrait(imageFile),
      };

      final response = await _client
          .from('group_photos')
          .insert(photoData)
          .select('id, url, storage_path, captured_at, uploader_id, is_portrait')
          .single();

      print('✅ Database record created: ${response['id']}');

      return response;
    } catch (e, stackTrace) {
      print('❌ Error uploading photo: $e');
      print(stackTrace);
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Delete a photo from storage and database
  Future<void> deletePhoto({
    required String photoId,
    required String storagePath,
  }) async {
    try {
      // 1. Delete from storage
      await _client.storage.from('memory_groups').remove([storagePath]);
      print('✅ Deleted from storage: $storagePath');

      // 2. Delete from database
      await _client.from('group_photos').delete().eq('id', photoId);
      print('✅ Deleted from database: $photoId');
    } catch (e) {
      print('❌ Error deleting photo: $e');
      throw Exception('Failed to delete photo: $e');
    }
  }

  /// Get signed URL for authenticated access to private bucket
  Future<String> getSignedUrl(String storagePath, {int expiresIn = 3600}) async {
    try {
      return await _client.storage
          .from('memory_groups')
          .createSignedUrl(storagePath, expiresIn);
    } catch (e) {
      throw Exception('Failed to get signed URL: $e');
    }
  }

  /// Determine MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension) {
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

  /// Check if image is portrait orientation
  Future<bool> _isPortrait(File imageFile) async {
    try {
      // Basic heuristic: if filename contains 'portrait' or check actual dimensions
      // For now, return false as default (can be enhanced with image package)
      return false;
    } catch (e) {
      return false;
    }
  }
}
