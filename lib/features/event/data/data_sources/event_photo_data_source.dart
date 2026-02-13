import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;

/// Data source for event photo operations using Supabase
/// Handles photo uploads to memory_groups storage bucket
class EventPhotoDataSource {
  final SupabaseClient _client;

  EventPhotoDataSource(this._client);

  /// Upload a photo to Supabase Storage and create database record
  ///
  /// Storage path: /{eventId}/{userId}/{timestamp}.jpg
  /// Bucket: memory_groups (private, requires auth)
  ///
  /// Returns the uploaded photo data including URL and storage path
  Future<Map<String, dynamic>> uploadPhoto({
    required String eventId,
    required File imageFile,
    required DateTime capturedAt,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 1. Generate storage path: /{eventId}/{userId}/{timestamp}.extension
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last.toLowerCase();
      final storagePath = '$eventId/$userId/$timestamp.$extension';

      // 2. Upload to Supabase Storage
      await _client.storage.from('memory_groups').upload(
            storagePath,
            imageFile,
            fileOptions: FileOptions(
              contentType: _getMimeType(extension),
              upsert: false,
            ),
          );

      // 3. Get public URL (will require signed URL for private bucket)
      final publicUrl =
          _client.storage.from('memory_groups').getPublicUrl(storagePath);

      // 4. Create database record in event_photos table
      final photoData = {
        'event_id': eventId,
        'url': publicUrl,
        'storage_path': storagePath,
        'captured_at': capturedAt.toIso8601String(),
        'uploader_id': userId,
        'is_portrait': await _isPortrait(imageFile),
      };

      final response = await _client
          .from('event_photos')
          .insert(photoData)
          .select(
              'id, url, storage_path, captured_at, uploader_id, is_portrait')
          .single();

      return response;
    } catch (e) {
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
      // 2. Delete from database
      await _client.from('event_photos').delete().eq('id', photoId);
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  /// Get signed URL for authenticated access to private bucket
  Future<String> getSignedUrl(String storagePath,
      {int expiresIn = 3600}) async {
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
  /// Returns true if height > width (portrait), false if width >= height (landscape/square)
  Future<bool> _isPortrait(File imageFile) async {
    try {
      // Read image file bytes
      final bytes = await imageFile.readAsBytes();

      // Decode image to get dimensions
      final image = img.decodeImage(bytes);

      if (image == null) {
        return false;
      }

      // Portrait if height > width
      final isPortrait = image.height > image.width;

      return isPortrait;
    } catch (e) {
      return false;
    }
  }

  /// Get all photos for an event with uploader information
  Future<List<Map<String, dynamic>>> getEventPhotos(String eventId) async {
    try {
      // Query event_photos with user info
      final response = await _client.from('event_photos').select('''
            id,
            url,
            storage_path,
            captured_at,
            uploader_id,
            is_portrait,
            uploader:uploader_id(id, name, avatar_url)
          ''').eq('event_id', eventId).order('captured_at', ascending: false);

      // Generate signed URLs for each photo
      final photos = <Map<String, dynamic>>[];
      for (final photo in response as List) {
        final signedUrl = await getSignedUrl(photo['storage_path'] as String);

        photos.add({
          'id': photo['id'],
          'url': signedUrl,
          'storage_path': photo['storage_path'],
          'captured_at': photo['captured_at'],
          'uploader_id': photo['uploader_id'],
          'is_portrait': photo['is_portrait'],
          'uploader_name': photo['uploader']?['name'],
          'uploader_avatar': photo['uploader']?['avatar_url'],
        });
      }

      return photos;
    } catch (e) {
      throw Exception('Failed to get event photos: $e');
    }
  }
}
