import '../repositories/group_repository.dart';

/// Use case para arquivar um grupo
class ArchiveGroup {
  final GroupRepository _repository;

  const ArchiveGroup(this._repository);

  Future<void> call(String groupId) async {
    if (groupId.trim().isEmpty) {
      throw ArgumentError('Group ID cannot be empty');
    }

    return await _repository.toggleArchive(groupId);
  }
}