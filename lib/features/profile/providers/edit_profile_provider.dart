import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/profile_entity.dart';
import '../domain/usecases/get_current_user_profile.dart';
import '../domain/usecases/update_profile.dart';
import '../domain/repositories/profile_repository.dart';
import '../data/fakes/fake_profile_repository.dart';

// Fake repository provider (override with real implementation when needed)
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FakeProfileRepository();
});

// Use case providers
final getCurrentUserProfileProvider = Provider<GetCurrentUserProfile>((ref) {
  return GetCurrentUserProfile(ref.read(profileRepositoryProvider));
});

final updateProfileProvider = Provider<UpdateProfile>((ref) {
  return UpdateProfile(ref.read(profileRepositoryProvider));
});

// Edit profile state provider
final editProfileProvider =
    StateNotifierProvider<EditProfileNotifier, AsyncValue<ProfileEntity>>((
      ref,
    ) {
      return EditProfileNotifier(
        ref.read(getCurrentUserProfileProvider),
        ref.read(updateProfileProvider),
      );
    });

/// State notifier for edit profile functionality
/// Manages profile loading and updating states
class EditProfileNotifier extends StateNotifier<AsyncValue<ProfileEntity>> {
  final GetCurrentUserProfile _getCurrentUserProfile;
  final UpdateProfile _updateProfile;

  EditProfileNotifier(this._getCurrentUserProfile, this._updateProfile)
    : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  /// Load the current user's profile
  Future<void> _loadProfile() async {
    try {
      final profile = await _getCurrentUserProfile();
      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update the profile with new information
  Future<void> updateProfile(ProfileEntity updatedProfile) async {
    try {
      final profile = await _updateProfile(updatedProfile);
      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh the profile data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadProfile();
  }
}
