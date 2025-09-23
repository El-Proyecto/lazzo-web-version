import '../repositories/group_repository.dart';

/// Use case para alternar o status de arquivo de um grupo
class ToggleGroupArchive {
  final GroupRepository repository;

  ToggleGroupArchive(this.repository);

  /// Alterna o status de arquivo de um grupo
  Future<void> call(String groupId) async {
    await repository.toggleArchive(groupId);
  }
}
