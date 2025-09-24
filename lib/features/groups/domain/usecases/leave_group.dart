import '../repositories/group_repository.dart';

/// Use case para sair de um grupo
class LeaveGroup {
  final GroupRepository _repository;

  const LeaveGroup(this._repository);

  Future<void> call(String groupId) async {
    await _repository.leaveGroup(groupId);
  }
}
