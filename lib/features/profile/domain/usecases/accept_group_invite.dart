import '../repositories/other_profile_repository.dart';

class AcceptGroupInvite {
  final OtherProfileRepository repository;

  const AcceptGroupInvite(this.repository);

  Future<bool> call({
    required String userId,
    required String groupId,
  }) {
    return repository.acceptGroupInvite(
      userId: userId,
      groupId: groupId,
    );
  }
}
