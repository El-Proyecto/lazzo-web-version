import '../repositories/group_repository.dart';

/// Use case para alternar o mute de um grupo
class ToggleGroupMute {
  final GroupRepository _repository;

  const ToggleGroupMute(this._repository);

  Future<void> call(String groupId, bool isMuted) async {
    await _repository.toggleMute(groupId, isMuted);
  }
}
