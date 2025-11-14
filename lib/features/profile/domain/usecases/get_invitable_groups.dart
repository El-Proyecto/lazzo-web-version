import '../entities/invite_group_entity.dart';
import '../repositories/other_profile_repository.dart';

/// Use case to get groups where current user can invite another user
class GetInvitableGroups {
  final OtherProfileRepository repository;

  const GetInvitableGroups(this.repository);

  Future<List<InviteGroupEntity>> call(String userId) {
    return repository.getInvitableGroups(userId);
  }
}
