import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

/// Use case for getting current user's profile
class GetCurrentUserProfile {
  final ProfileRepository _repository;

  const GetCurrentUserProfile(this._repository);

  Future<ProfileEntity> call() async {
    return await _repository.getCurrentUserProfile();
  }
}
