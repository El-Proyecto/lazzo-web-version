import '../../domain/entities/group_invite_link_entity.dart';
import '../../domain/repositories/group_invite_repository.dart';
import '../data_sources/group_invite_remote_data_source.dart';

class GroupInviteRepositoryImpl implements GroupInviteRepository {
  final GroupInviteRemoteDataSource _dataSource;

  GroupInviteRepositoryImpl(this._dataSource);

  @override
  Future<GroupInviteLinkEntity> createInviteLink({
    required String groupId,
    int? maxUses,
    int expiresInHours = 48,
  }) async {
    try {
      final model = await _dataSource.createInviteLink(
        groupId: groupId,
        maxUses: maxUses,
        expiresInHours: expiresInHours,
      );
      final entity = model.toEntity();
      return entity;
    } catch (e) {
      throw Exception('Failed to create invite link: $e');
    }
  }

  @override
  Future<String> acceptInviteByToken(String token) async {
    try {
      final groupId = await _dataSource.acceptInviteByToken(token);
      return groupId;
    } catch (e) {
      throw Exception('Failed to accept invite: $e');
    }
  }
}
