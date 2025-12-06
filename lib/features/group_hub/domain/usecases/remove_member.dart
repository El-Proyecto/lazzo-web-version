import '../repositories/group_details_repository.dart';

/// Use case for removing a member from a group
/// 
/// Business rules:
/// - Only admins can remove members
/// - Cannot remove yourself (use leave group instead)
/// - If removing an admin, at least one other admin must remain
class RemoveMember {
  final GroupDetailsRepository _repository;

  RemoveMember(this._repository);

  Future<void> call(String groupId, String userId) async {
    return await _repository.removeMember(groupId, userId);
  }
}
