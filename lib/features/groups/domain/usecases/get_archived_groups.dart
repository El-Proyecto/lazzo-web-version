import '../entities/group.dart';
import '../repositories/group_repository.dart';

/// Use case para obter grupos arquivados
class GetArchivedGroups {
  final GroupRepository _repository;

  const GetArchivedGroups(this._repository);

  Future<List<Group>> call() async {
    return await _repository.getArchivedGroups();
  }
}