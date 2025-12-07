// Real implementation using Supabase data source

import 'package:image_picker/image_picker.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../data_sources/profile_remote_data_source.dart';
import '../data_sources/profile_memory_data_source.dart';
import '../models/profile_model.dart';
import '../../../../services/storage_service.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remote;
  final ProfileMemoryDataSource memoryDataSource;
  final StorageService storageService;

  ProfileRepositoryImpl(
    this.remote,
    this.memoryDataSource,
    this.storageService,
  );

  @override
  Future<ProfileEntity> getCurrentUserProfile() async {
    final profileModel = await remote.fetchCurrentUserProfile();
    if (profileModel == null) {
      throw Exception('Profile not found');
    }

    // Fetch memories for the profile using ProfileMemoryDataSource
    final memoryMaps = await memoryDataSource.getUserMemories(profileModel.id);
    final memoryModels = memoryMaps.map((map) => MemoryModel.fromMap(map)).toList();
    
    // Generate signed URLs for memory covers
    final memories = <MemoryEntity>[];
    for (final model in memoryModels) {
      String? signedUrl;
      if (model.coverStoragePath != null) {
        signedUrl = await storageService.getSignedUrl(model.coverStoragePath!);
      }
      memories.add(model.toEntity(signedUrl: signedUrl));
    }

    // Get signed URL for profile picture if it exists
    String? profileSignedUrl;
    if (profileModel.avatarUrl != null && profileModel.avatarUrl!.isNotEmpty) {
      profileSignedUrl = await remote.getProfilePictureSignedUrl(profileModel.avatarUrl);
    }

    // Create a new model with signed URL if available
    final modelWithSignedUrl = profileSignedUrl != null
        ? ProfileModel(
            id: profileModel.id,
            name: profileModel.name,
            email: profileModel.email,
            avatarUrl: profileSignedUrl,
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

    // Fetch memories for the profile using ProfileMemoryDataSource
    final memoryMaps = await memoryDataSource.getUserMemories(userId);
    final memoryModels = memoryMaps.map((map) => MemoryModel.fromMap(map)).toList();
    
    // Generate signed URLs for memory covers
    final memories = <MemoryEntity>[];
    for (final model in memoryModels) {
      String? signedUrl;
      if (model.coverStoragePath != null) {
        signedUrl = await storageService.getSignedUrl(model.coverStoragePath!);
      }
      memories.add(model.toEntity(signedUrl: signedUrl));
    }

    // Get signed URL for profile picture if it exists
    String? profileSignedUrl;
    if (profileModel.avatarUrl != null && profileModel.avatarUrl!.isNotEmpty) {
      profileSignedUrl = await remote.getProfilePictureSignedUrl(profileModel.avatarUrl);
    }

    // Create a new model with signed URL if available
    final modelWithSignedUrl = profileSignedUrl != null
        ? ProfileModel(
            id: profileModel.id,
            name: profileModel.name,
            email: profileModel.email,
            avatarUrl: profileSignedUrl,
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

    // Fetch updated memories using ProfileMemoryDataSource
    final memoryMaps = await memoryDataSource.getUserMemories(profile.id);
    final memoryModels = memoryMaps.map((map) => MemoryModel.fromMap(map)).toList();
    
    // Generate signed URLs for memory covers
    final memories = <MemoryEntity>[];
    for (final model in memoryModels) {
      String? signedUrl;
      if (model.coverStoragePath != null) {
        signedUrl = await storageService.getSignedUrl(model.coverStoragePath!);
      }
      memories.add(model.toEntity(signedUrl: signedUrl));
    }

    return updatedModel.toEntity(memories: memories);
  }

  @override
  Future<List<MemoryEntity>> getUserMemories(String userId) async {
    final memoryMaps = await memoryDataSource.getUserMemories(userId);
    final memoryModels = memoryMaps.map((map) => MemoryModel.fromMap(map)).toList();
    
    // Generate signed URLs for memory covers
    final memories = <MemoryEntity>[];
    for (final model in memoryModels) {
      String? signedUrl;
      if (model.coverStoragePath != null) {
        signedUrl = await storageService.getSignedUrl(model.coverStoragePath!);
      }
      memories.add(model.toEntity(signedUrl: signedUrl));
    }
    
    return memories;
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
