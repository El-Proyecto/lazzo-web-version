import '../entities/action.dart';
import '../repositories/action_repository.dart';

/// Get all pending host actions for the current user.
class GetUserActions {
  final ActionRepository repository;

  const GetUserActions(this.repository);

  Future<List<ActionEntity>> call() {
    return repository.getActions();
  }
}

/// Dismiss an action the host doesn't want to see anymore.
class DismissAction {
  final ActionRepository repository;

  const DismissAction(this.repository);

  Future<void> call(String actionId) {
    return repository.dismissAction(actionId);
  }
}
