import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

/// Use case for getting profile by user ID
class GetProfileById {
  final ProfileRepository _repository;

  const GetProfileById(this._repository);

  Future<ProfileEntity> call(String userId) async {
    return await _repository.getProfileById(userId);
  }
}
