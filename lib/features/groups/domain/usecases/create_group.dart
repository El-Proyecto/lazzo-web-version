import '../entities/group_entity.dart';
import '../repositories/group_repository.dart';

/// Use case para criar um novo grupo usando GroupEntity
class CreateGroup {
  final GroupRepository _repository;

  const CreateGroup(this._repository);

  Future<GroupEntity> call(GroupEntity group) async {
    // Business rule validation
    if (group.name.trim().isEmpty) {
      throw ArgumentError('Group name cannot be empty');
    }

    if (group.name.trim().length < 2) {
      throw ArgumentError('Group name must be at least 2 characters');
    }

    return await _repository.createGroupEntity(group);
  }
}
