// Calls Supabase for profile operations

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/profile_model.dart';
import '../../../../shared/utils/image_compression_service.dart';

class ProfileRemoteDataSource {
  final SupabaseClient client;
  static const String _bucketName = 'users-profile-pic'; // Bucket privado para fotos de perfil

  ProfileRemoteDataSource(this.client);

  /// Fetch current user's profile
  /// Includes retry logic to handle race conditions after login
  Future<ProfileModel?> fetchCurrentUserProfile() async {
    try {
      // Try to get user, with one retry if null (race condition after login)
      var user = client.auth.currentUser;
      if (user == null) {
        // Wait a moment for auth to sync, then try again
        await Future.delayed(const Duration(milliseconds: 300));
        user = client.auth.currentUser;
      }
      if (user == null) return null;

      final response = await client
          .from('users')
          .select('id, name, email, avatar_url, city, birth_date')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;
      
      // Convert storage path to signed URL (private bucket)
      if (response['avatar_url'] != null) {
        response['avatar_url'] = await getProfilePictureSignedUrl(response['avatar_url'] as String);
      }
      
      return ProfileModel.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch profile by user ID
  Future<ProfileModel?> fetchProfileById(String userId) async {
    try {
      final response = await client
          .from('users')
          .select('id, name, email, avatar_url, city, birth_date')
          .eq('id', userId)
          .maybeSingle();

      return response == null ? null : ProfileModel.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update current user's profile
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final profileData = profile.toMap();
      
      final response = await client
          .from('users')
          .update(profileData)
          .eq('id', user.id)
          .select('id, name, email, avatar_url, city, birth_date')
          .single();

      
      // Convert storage path to signed URL (private bucket)
      if (response['avatar_url'] != null) {
        response['avatar_url'] = await getProfilePictureSignedUrl(response['avatar_url'] as String);
              }
      
      return ProfileModel.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch user's memories/events

  /// Upload profile picture to storage
  Future<String> uploadProfilePicture(XFile imageFile) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

            
      // Use ensureStoragePath to handle local files properly
      final storagePath = await ensureStoragePath(
        input: imageFile.path,
        userId: user.id,
      );
      
      // Update database with the storage path (use updated_at instead of photo_updated_at)
      await client
          .from('users')
          .update({
            'avatar_url': storagePath,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
      
            return storagePath;
    } catch (e) {
            throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Get signed URL for profile picture (private bucket - requires authentication)
  Future<String?> getProfilePictureSignedUrl(String? avatarUrl) async {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return null;
    }

    try {
            
      // If it's a local path, we can't generate a signed URL
      if (avatarUrl.startsWith('/') || avatarUrl.contains('cache') || avatarUrl.contains('data/user')) {
                throw Exception('Invalid photo path - local paths are not supported');
      }
      
      // If it's already a full URL (signed URL from previous call), just return it
      if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
                return avatarUrl;
      }
      
      // Generate signed URL for storage path (private bucket - 1 hour validity)
      final signedUrl = await client.storage
          .from(_bucketName)
          .createSignedUrl(avatarUrl, 3600); // 1 hour validity
      
            return signedUrl;
    } catch (e) {
            return null;
    }
  }

  /// Ensures the input path is a valid storage path, uploading local files if needed
  Future<String> ensureStoragePath({
    required String input,
    required String userId,
  }) async {
    // 1) Already a URL?
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }

    // 2) Is local? Upload and return object path
    final isLocal = input.startsWith('/') ||
                    input.startsWith('file://') ||
                    input.startsWith('content://') ||
                    input.contains('/data/') ||
                    input.contains('cache');
    
    if (isLocal) {
            
      // Check if file exists
      final file = File(input.replaceFirst('file://', ''));
      if (!await file.exists()) {
        throw Exception('File not found: $input');
      }
      
      // Create XFile and compress using existing service
      final xFile = XFile(input);
      final compressedBytes = await ImageCompressionService.compressToWebP(xFile);
      
      // Create object path with timestamp for versioning
      // CRITICAL: Path MUST start with userId (not "users/userId") for RLS policy to work
      // Policy checks: (storage.foldername(name))[1] = auth.uid()::text
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final objectPath = '$userId/profile_$timestamp.webp';
      
      // Upload to storage
      await client.storage.from(_bucketName).uploadBinary(
        objectPath, 
        compressedBytes,
        fileOptions: const FileOptions(
          contentType: 'image/webp',
          upsert: true,
        ),
      );
      
            return objectPath; // Return just the object path
    }

    // 3) Looks like storage path (bucket/object or just object)
    if (RegExp(r'^[^/]+/.+').hasMatch(input)) {
      // If it includes bucket name, extract just the object path
      if (input.startsWith('$_bucketName/')) {
        return input.substring(_bucketName.length + 1);
      }
      return input;
    }

    throw Exception('Unrecognized path: $input');
  }

  /// Delete profile picture from storage (deletes entire user folder)
  Future<void> deleteProfilePicture(String? currentAvatarUrl) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      
      // Delete ALL files in the user's folder, not just the current avatar
      // This ensures cleanup of old/orphaned profile pictures
      try {
        // List all files in user's folder
        final filesList = await client.storage
            .from(_bucketName)
            .list(path: user.id);
        
        if (filesList.isNotEmpty) {
          // Build full paths for all files
          final filePaths = filesList
              .map((file) => '${user.id}/${file.name}')
              .toList();
          
          // Delete all files
          await client.storage
              .from(_bucketName)
              .remove(filePaths);
          
                  } else {
                  }
      } catch (e) {
                // Continue with database update even if storage deletion fails
      }

      // Update database to remove avatar_url
      await client
          .from('users')
          .update({
            'avatar_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

          } catch (e) {
            throw Exception('Failed to delete profile picture: $e');
    }
  }
}
