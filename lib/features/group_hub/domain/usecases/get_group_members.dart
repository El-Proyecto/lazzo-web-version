import '../entities/group_member_entity.dart';
import '../repositories/group_details_repository.dart';

/// Use case to get group members
class GetGroupMembers {
  final GroupDetailsRepository _repository;

  const GetGroupMembers(this._repository);

  Future<List<GroupMemberEntity>> call(String groupId) {
    return _repository.getGroupMembers(groupId);
  }
}
