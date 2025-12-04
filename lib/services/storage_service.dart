import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Service for managing Supabase Storage operations
/// Handles file uploads, downloads, and deletions
class StorageService {
  final SupabaseClient _client;

  StorageService(this._client);

  /// Upload a photo to the memory_groups bucket (PRIVATE)
  /// Path convention: /groupId/memoryId/userId/uuid.jpg
  /// 
  /// Returns the storage path (not URL - URLs are generated on-demand with RLS)
  Future<String> uploadMemoryPhoto({
    required String groupId,
    required String memoryId,
    required String userId,
    required File file,
  }) async {
    try {
      // Generate unique filename
      final uuid = const Uuid().v4();
      final extension = path.extension(file.path);
      final fileName = '$uuid$extension';
      
      // Storage path following convention
      final storagePath = '$groupId/$memoryId/$userId/$fileName';
      
      print('📤 Uploading photo to: $storagePath');
      
      // Upload to Supabase Storage (private bucket)
      await _client.storage
          .from('memory_groups')
          .upload(storagePath, file);
      
      print('✅ Photo uploaded successfully to: $storagePath');
      
      // Return storage path (not URL - we'll generate signed URLs on-demand)
      return storagePath;
    } catch (e) {
      print('❌ Failed to upload photo: $e');
      rethrow;
    }
  }

  /// Get a signed URL for a private photo (expires after 1 hour)
  /// This validates RLS policies before generating the URL
  Future<String> getSignedUrl(String storagePath, {String bucket = 'memory_groups', int expiresInSeconds = 3600}) async {
    try {
      final signedUrl = await _client.storage
          .from(bucket)
          .createSignedUrl(storagePath, expiresInSeconds);
      
      return signedUrl;
    } catch (e) {
      print('❌ Failed to generate signed URL for $bucket/$storagePath: $e');
      rethrow;
    }
  }

  /// Delete a photo from storage
  Future<void> deleteMemoryPhoto({
    required String groupId,
    required String memoryId,
    required String userId,
    required String fileName,
  }) async {
    try {
      final storagePath = '$groupId/$memoryId/$userId/$fileName';
      
      await _client.storage
          .from('memory_groups')
          .remove([storagePath]);
      
      print('🗑️ Photo deleted: $storagePath');
    } catch (e) {
      print('❌ Failed to delete photo: $e');
      rethrow;
    }
  }

  /// Get thumbnail URL (Supabase can auto-generate thumbnails)
  String getThumbnailUrl(String publicUrl, {int width = 300}) {
    return '$publicUrl?width=$width&quality=80';
  }
}

