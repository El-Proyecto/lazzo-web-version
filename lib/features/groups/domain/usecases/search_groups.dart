import '../entities/group.dart';
import '../repositories/group_repository.dart';

/// Use case para buscar grupos por termo
class SearchGroups {
  final GroupRepository _repository;

  const SearchGroups(this._repository);

  Future<List<Group>> call(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      return await _repository.getUserGroups();
    }
    return await _repository.searchGroups(searchTerm);
  }
}
