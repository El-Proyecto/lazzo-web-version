import '../repositories/group_details_repository.dart';

/// Use case to update a member's role (promote to admin or demote to member)
/// Validates that at least one admin remains in the group
class UpdateMemberRole {
  final GroupDetailsRepository _repository;

  const UpdateMemberRole(this._repository);

  /// Update member role
  /// [groupId] - The group ID
  /// [userId] - The user ID to update
  /// [isAdmin] - true to promote to admin, false to demote to member
  /// Throws exception if trying to demote the last admin
  Future<void> call(String groupId, String userId, bool isAdmin) {
    return _repository.updateMemberRole(groupId, userId, isAdmin);
  }
}
