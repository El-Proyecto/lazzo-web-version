import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

/// Use case for updating the current user's profile
/// Handles profile information updates following Clean Architecture
class UpdateProfile {
  final ProfileRepository _repository;

  UpdateProfile(this._repository);

  /// Update the current user's profile with new information
  Future<ProfileEntity> call(ProfileEntity updatedProfile) async {
    return await _repository.updateProfile(updatedProfile);
  }
}
