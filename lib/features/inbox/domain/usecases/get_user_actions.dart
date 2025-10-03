import '../entities/action.dart';
import '../repositories/action_repository.dart';

class GetUserActions {
  final ActionRepository repository;

  const GetUserActions(this.repository);

  Future<List<ActionEntity>> call({
    int limit = 20,
    int offset = 0,
    String? groupId,
    String? eventId,
  }) {
    return repository.getActions(
      limit: limit,
      offset: offset,
      groupId: groupId,
      eventId: eventId,
    );
  }
}

class GetActionsByTimeLeft {
  final ActionRepository repository;

  const GetActionsByTimeLeft(this.repository);

  Future<List<ActionEntity>> call({int limit = 20, bool overdueFirst = true}) {
    return repository.getActionsByTimeLeft(
      limit: limit,
      overdueFirst: overdueFirst,
    );
  }
}

class CompleteAction {
  final ActionRepository repository;

  const CompleteAction(this.repository);

  Future<void> call(String id) {
    return repository.markAsCompleted(id);
  }
}
