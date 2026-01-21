import '../entities/group_entity.dart';

/// Repository interface for updating group information
abstract class UpdateGroupRepository {
  /// Update group details (name, description, photo)
  /// Returns updated GroupEntity on success
  Future<GroupEntity> updateGroup({
    required String groupId,
    required String name,
    String? description,
    String? photoPath,
  });
}
