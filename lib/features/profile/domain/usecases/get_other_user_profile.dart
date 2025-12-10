import '../entities/other_profile_entity.dart';
import '../repositories/other_profile_repository.dart';

/// Use case to get another user's profile
class GetOtherUserProfile {
  final OtherProfileRepository repository;

  const GetOtherUserProfile(this.repository);

  Future<OtherProfileEntity> call(String userId) async {
final result = await repository.getOtherUserProfile(userId);
return result;
  }
}
