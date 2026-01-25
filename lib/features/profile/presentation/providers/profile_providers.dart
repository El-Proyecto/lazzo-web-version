import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_current_user_profile.dart';
import '../../domain/usecases/update_profile.dart';
import '../../data/data_sources/profile_remote_data_source.dart';
import '../../data/fakes/fake_profile_repository.dart';

/// Default ProfileRepository provider - points to fake for development
/// Will be overridden in main.dart to use real Supabase implementation
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FakeProfileRepository();
});

/// ProfileDataSource provider for Supabase operations
final profileDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(Supabase.instance.client);
});

/// GetCurrentUserProfile UseCase provider
final getCurrentUserProfileUseCaseProvider = Provider<GetCurrentUserProfile>((ref) {
  return GetCurrentUserProfile(ref.watch(profileRepositoryProvider));
});

/// UpdateProfile UseCase provider
final updateProfileUseCaseProvider = Provider<UpdateProfile>((ref) {
  return UpdateProfile(ref.watch(profileRepositoryProvider));
});

/// Provider for current user profile data (shared between all profile screens)
final currentUserProfileProvider = FutureProvider<ProfileEntity>((ref) async {
  final getCurrentUserProfile = ref.watch(getCurrentUserProfileUseCaseProvider);
  final profile = await getCurrentUserProfile.call();
  return profile;
});

/// Edit Profile Controller provider for managing form operations
final editProfileControllerProvider = Provider<EditProfileController>((ref) {
  return EditProfileController(ref);
});

/// Simple controller for edit profile operations
class EditProfileController {
  final Ref _ref;

  EditProfileController(this._ref);

  /// Update profile and sync UI automatically
  Future<ProfileEntity> updateProfile(ProfileEntity profile) async {
        
    try {
      // Update via use case
      final updateUseCase = _ref.read(updateProfileUseCaseProvider);
      final updatedProfile = await updateUseCase.call(profile);
      
            
      // Invalidate to trigger UI refresh
      _ref.invalidate(currentUserProfileProvider);
      
      return updatedProfile;
    } catch (error) {
            rethrow;
    }
  }
}