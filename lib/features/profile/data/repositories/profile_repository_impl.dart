// Real implementation using Supabase data source

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

    return profileModel.toEntity(memories: memories);
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

    return profileModel.toEntity(memories: memories);
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
}
