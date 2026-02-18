import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import '../../../../services/storage_service.dart';

/// Data source for event photo operations using Supabase
/// Handles photo uploads to memory_groups storage bucket
class EventPhotoDataSource {
  final SupabaseClient _client;
  final StorageService _storageService;

  EventPhotoDataSource(this._client)
      : _storageService = StorageService(_client);

  /// Upload a photo to Supabase Storage and create database record
  ///
  /// Uses StorageService for consistent path convention:
  /// /{eventId}/{eventId}/{userId}/{uuid}.extension
  /// Bucket: memory_groups (private, requires auth)
  ///
  /// Returns the uploaded photo data including storage path
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

      // 1. Upload to storage using StorageService (same path convention as MemoryPhotoDataSource)
      final storagePath = await _storageService.uploadMemoryPhoto(
        eventId: eventId,
        memoryId: eventId,
        userId: userId,
        file: imageFile,
      );

      // 2. Create database record in event_photos table
      final photoData = {
        'event_id': eventId,
        'url':
            storagePath, // Store path, not URL — signed URLs generated on-demand
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
      return await _storageService.getSignedUrl(storagePath,
          expiresInSeconds: expiresIn);
    } catch (e) {
      throw Exception('Failed to get signed URL: $e');
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
  /// Limited to 50 photos per fetch to avoid unbounded queries.
  /// Use [offset] for pagination when needed.
  Future<List<Map<String, dynamic>>> getEventPhotos(
    String eventId, {
    int limit = 50,
    int offset = 0,
  }) async {
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
          ''').eq('event_id', eventId).order('captured_at', ascending: false)
          .range(offset, offset + limit - 1);

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
