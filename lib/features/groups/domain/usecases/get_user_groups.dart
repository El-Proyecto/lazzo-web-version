import '../entities/group.dart';
import '../repositories/group_repository.dart';

/// Use case para obter os grupos do usuário
class GetUserGroups {
  final GroupRepository _repository;

  const GetUserGroups(this._repository);

  Future<List<Group>> call() async {
    return await _repository.getUserGroups();
  }
}
