import '../repositories/group_details_repository.dart';

/// Use case to toggle mute/unmute for a group
class ToggleGroupMute {
  final GroupDetailsRepository _repository;

  const ToggleGroupMute(this._repository);

  Future<void> call(String groupId, bool isMuted) {
    return _repository.toggleMute(groupId, isMuted);
  }
}
