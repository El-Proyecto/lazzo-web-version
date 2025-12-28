import '../entities/group_invite_link_entity.dart';
import '../repositories/group_invite_repository.dart';

class CreateGroupInviteLink {
  final GroupInviteRepository repository;

  CreateGroupInviteLink(this.repository);

  Future<GroupInviteLinkEntity> call({
    required String groupId,
    int? maxUses,
    int expiresInHours = 48,
  }) {
    return repository.createInviteLink(
      groupId: groupId,
      maxUses: maxUses,
      expiresInHours: expiresInHours,
    );
  }
}
