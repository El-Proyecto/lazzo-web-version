import '../repositories/other_profile_repository.dart';

/// Use case to invite a user to a group
class InviteToGroup {
  final OtherProfileRepository repository;

  const InviteToGroup(this.repository);

  Future<bool> call({
    required String userId,
    required String groupId,
  }) {
    return repository.inviteToGroup(
      userId: userId,
      groupId: groupId,
    );
  }
}
