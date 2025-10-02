import '../entities/action.dart';

abstract class ActionRepository {
  Future<List<ActionEntity>> getActions({
    int limit = 20,
    int offset = 0,
    String? groupId,
    String? eventId,
  });

  Future<List<ActionEntity>> getActionsByTimeLeft({
    int limit = 20,
    bool overdueFirst = true,
  });

  Future<ActionEntity?> getActionById(String id);

  Future<void> markAsCompleted(String id);

  Future<void> updateActionStatus(String id, ActionStatus status);

  Future<int> getPendingCount();

  Stream<List<ActionEntity>> watchActions();
}
