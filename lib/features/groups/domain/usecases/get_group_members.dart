import '../entities/group_member_entity.dart';
import '../repositories/group_repository.dart';

class GetGroupMembers {
  final GroupRepository _repository;

  GetGroupMembers(this._repository);

  Future<List<GroupMemberEntity>> call(String groupId) async {
    return await _repository.getGroupMembersEntities(groupId);
  }
}