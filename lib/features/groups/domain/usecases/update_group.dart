import '../entities/group_entity.dart';
import '../repositories/update_group_repository.dart';

/// Use case for updating an existing group
class UpdateGroup {
  final UpdateGroupRepository repository;

  const UpdateGroup(this.repository);

  /// Execute update group operation
  Future<GroupEntity> call({
    required String groupId,
    required String name,
    String? description,
    String? photoPath,
    required bool canEditSettings,
    required bool canAddMembers,
    required bool canSendMessages,
  }) {
    return repository.updateGroup(
      groupId: groupId,
      name: name,
      description: description,
      photoPath: photoPath,
      canEditSettings: canEditSettings,
      canAddMembers: canAddMembers,
      canSendMessages: canSendMessages,
    );
  }
}
