import '../repositories/other_profile_repository.dart';

class DeclineGroupInvite {
  final OtherProfileRepository repository;

  const DeclineGroupInvite(this.repository);

  Future<bool> call({
    required String userId,
    required String groupId,
  }) {
    return repository.declineGroupInvite(
      userId: userId,
      groupId: groupId,
    );
  }
}
