import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_permissions.dart';
import '../../domain/repositories/update_group_repository.dart';

/// Fake implementation of UpdateGroupRepository for P1 development
class FakeUpdateGroupRepository implements UpdateGroupRepository {
  @override
  Future<GroupEntity> updateGroup({
    required String groupId,
    required String name,
    String? description,
    String? photoPath,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Return updated group entity with default permissions (all true)
    return GroupEntity(
      id: groupId,
      name: name,
      description: description,
      photoUrl: photoPath, // In real impl, this would be storage URL
      permissions: const GroupPermissions(
        membersCanInvite: true,
        membersCanAddMembers: true,
        membersCanCreateEvents: true,
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
  }
}
