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
  Future<ProfileModel?> fetchCurrentUserProfile() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final response = await client
          .from('users')
          .select('id, name, email, avatar_url, city, birth_date')
          .eq('id', user.id)
          .maybeSingle();

      return response == null ? null : ProfileModel.fromMap(response);
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

      final response = await client
          .from('users')
          .update(profile.toMap())
          .eq('id', user.id)
          .select('id, name, email, avatar_url, city, birth_date')
          .single();

      return ProfileModel.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch user's memories/events
  Future<List<MemoryModel>> fetchUserMemories(String userId) async {
    try {
      final response = await client
          .from('memories')
          .select('mem_id, mem_title, photo_id, mem_date, mem_location')
          .order('mem_location', ascending: false);

      return response.map((json) => MemoryModel.fromMap(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Upload profile picture to storage
  Future<String> uploadProfilePicture(XFile imageFile) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      print('🚀 [ProfileDataSource] Starting profile picture upload for user: ${user.id}');
      
      // Use ensureStoragePath to handle local files properly
      final storagePath = await ensureStoragePath(
        input: imageFile.path,
        userId: user.id,
      );
      
      // Update database with the storage path
      await client
          .from('users')
          .update({
            'avatar_url': storagePath,
            'photo_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
      
      print('✅ [ProfileDataSource] Profile picture upload completed: $storagePath');
      return storagePath;
    } catch (e) {
      print('❌ [ProfileDataSource] Profile picture upload failed: $e');
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Get signed URL for profile picture
  Future<String?> getProfilePictureSignedUrl(String? avatarUrl) async {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return null;
    }

    try {
      print('🔗 [ProfileDataSource] Getting signed URL for: $avatarUrl');
      
      // If it's a local path, we can't generate a signed URL
      if (avatarUrl.startsWith('/') || avatarUrl.contains('cache') || avatarUrl.contains('data/user')) {
        print('   ⚠️ Local path detected, cannot generate signed URL');
        return null;
      }
      
      // Generate signed URL for storage path (expires in 1 hour)
      final signedUrl = await client.storage
          .from(_bucketName)
          .createSignedUrl(avatarUrl, 3600); // 1 hour expiry
      
      print('   ✅ Signed URL created successfully');
      return signedUrl;
    } catch (e) {
      print('   ❌ Failed to create signed URL: $e');
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
      print('📤 [ProfileDataSource] Converting local path to storage path: $input');
      
      // Check if file exists
      final file = File(input.replaceFirst('file://', ''));
      if (!await file.exists()) {
        throw Exception('File not found: $input');
      }
      
      // Create XFile and compress using existing service
      final xFile = XFile(input);
      final compressedBytes = await ImageCompressionService.compressToWebP(xFile);
      
      // Create object path with timestamp for versioning
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final objectPath = 'users/$userId/profile_$timestamp.webp';
      
      // Upload to storage
      await client.storage.from(_bucketName).uploadBinary(
        objectPath, 
        compressedBytes,
        fileOptions: const FileOptions(
          contentType: 'image/webp',
          upsert: true,
        ),
      );
      
      print('✅ [ProfileDataSource] Local file uploaded to storage: $objectPath');
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

  /// Delete profile picture from storage
  Future<void> deleteProfilePicture(String? currentAvatarUrl) async {
    if (currentAvatarUrl == null || currentAvatarUrl.isEmpty) {
      return;
    }

    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      print('🗑️ [ProfileDataSource] Deleting profile picture: $currentAvatarUrl');

      // Only delete if it's a storage path (not a URL)
      if (!currentAvatarUrl.startsWith('http')) {
        await client.storage
            .from(_bucketName)
            .remove([currentAvatarUrl]);
        
        print('   ✅ Profile picture deleted from storage');
      }

      // Update database to remove avatar_url
      await client
          .from('users')
          .update({
            'avatar_url': null,
            'photo_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      print('   ✅ Profile picture reference removed from database');
    } catch (e) {
      print('   ❌ Failed to delete profile picture: $e');
      throw Exception('Failed to delete profile picture: $e');
    }
  }
}
