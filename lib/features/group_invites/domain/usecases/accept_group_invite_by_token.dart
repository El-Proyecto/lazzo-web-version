import '../repositories/group_invite_repository.dart';

class AcceptGroupInviteByToken {
  final GroupInviteRepository repository;

  AcceptGroupInviteByToken(this.repository);

  Future<String> call(String token) {
    return repository.acceptInviteByToken(token);
  }
}
