import '../repositories/group_repository.dart';

/// Use case para alternar o status de pin de um grupo
class ToggleGroupPin {
  final GroupRepository repository;

  ToggleGroupPin(this.repository);

  /// Alterna o status de pin de um grupo
  Future<void> call(String groupId) async {
    await repository.togglePin(groupId);
  }
}
