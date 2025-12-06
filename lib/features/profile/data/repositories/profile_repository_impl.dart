// Real implementation using Supabase data source

import 'package:image_picker/image_picker.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../data_sources/profile_remote_data_source.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remote;

  ProfileRepositoryImpl(this.remote);

  @override
  Future<ProfileEntity> getCurrentUserProfile() async {
    final profileModel = await remote.fetchCurrentUserProfile();
    if (profileModel == null) {
      throw Exception('Profile not found');
    }

    // Fetch memories for the profile
    final memoryModels = await remote.fetchUserMemories(profileModel.id);
    final memories = memoryModels.map((m) => m.toEntity()).toList();

    // Get signed URL for profile picture if it exists
    String? signedUrl;
    if (profileModel.avatarUrl != null && profileModel.avatarUrl!.isNotEmpty) {
      signedUrl = await remote.getProfilePictureSignedUrl(profileModel.avatarUrl);
    }

    // Create a new model with signed URL if available
    final modelWithSignedUrl = signedUrl != null
        ? ProfileModel(
            id: profileModel.id,
            name: profileModel.name,
            email: profileModel.email,
            avatarUrl: signedUrl,
            city: profileModel.city,
            birthDate: profileModel.birthDate,
          )
        : profileModel;

    return modelWithSignedUrl.toEntity(memories: memories);
  }

  @override
  Future<ProfileEntity> getProfileById(String userId) async {
    final profileModel = await remote.fetchProfileById(userId);
    if (profileModel == null) {
      throw Exception('Profile not found');
    }

    // Fetch memories for the profile
    final memoryModels = await remote.fetchUserMemories(userId);
    final memories = memoryModels.map((m) => m.toEntity()).toList();

    // Get signed URL for profile picture if it exists
    String? signedUrl;
    if (profileModel.avatarUrl != null && profileModel.avatarUrl!.isNotEmpty) {
      signedUrl = await remote.getProfilePictureSignedUrl(profileModel.avatarUrl);
    }

    // Create a new model with signed URL if available
    final modelWithSignedUrl = signedUrl != null
        ? ProfileModel(
            id: profileModel.id,
            name: profileModel.name,
            email: profileModel.email,
            avatarUrl: signedUrl,
            city: profileModel.city,
            birthDate: profileModel.birthDate,
          )
        : profileModel;

    return modelWithSignedUrl.toEntity(memories: memories);
  }

  @override
  Future<ProfileEntity> updateProfile(ProfileEntity profile) async {
    final profileModel = ProfileModel.fromEntity(profile);
    final updatedModel = await remote.updateProfile(profileModel);

    // Fetch updated memories
    final memoryModels = await remote.fetchUserMemories(profile.id);
    final memories = memoryModels.map((m) => m.toEntity()).toList();

    return updatedModel.toEntity(memories: memories);
  }

  @override
  Future<List<MemoryEntity>> getUserMemories(String userId) async {
    final memoryModels = await remote.fetchUserMemories(userId);
    return memoryModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<String> uploadProfilePicture(XFile imageFile) async {
    try {
            
      final storagePath = await remote.uploadProfilePicture(imageFile);
      
            return storagePath;
    } catch (e) {
            throw Exception('Failed to upload profile picture: $e');
    }
  }

  @override
  Future<String?> getProfilePictureUrl(String? avatarUrl) async {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return null;
    }

    try {
      // Generate signed URL for private storage
      final signedUrl = await remote.getProfilePictureSignedUrl(avatarUrl);
      return signedUrl;
    } catch (e) {
            return null;
    }
  }

  @override
  Future<void> deleteProfilePicture() async {
    try {
            
      // First get current profile to find current avatar URL
      final profile = await getCurrentUserProfile();
      await remote.deleteProfilePicture(profile.profileImageUrl);
      
          } catch (e) {
            throw Exception('Failed to delete profile picture: $e');
    }
  }
}
