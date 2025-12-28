import '../entities/group_invite_link_entity.dart';

abstract class GroupInviteRepository {
  Future<GroupInviteLinkEntity> createInviteLink({
    required String groupId,
    int? maxUses,
    int expiresInHours = 48,
  });

  Future<String> acceptInviteByToken(String token);
}
