import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/action.dart';
import '../../domain/repositories/action_repository.dart';
import '../../domain/usecases/get_user_actions.dart';
import '../../data/fakes/fake_action_repository.dart';

// Repository provider - defaults to fake
final actionRepositoryProvider = Provider<ActionRepository>((ref) {
  return FakeActionRepository();
});

// Use case providers
final getUserActionsUseCaseProvider = Provider<GetUserActions>((ref) {
  return GetUserActions(ref.watch(actionRepositoryProvider));
});

final getActionsByTimeLeftUseCaseProvider = Provider<GetActionsByTimeLeft>((
  ref,
) {
  return GetActionsByTimeLeft(ref.watch(actionRepositoryProvider));
});

final completeActionUseCaseProvider = Provider<CompleteAction>((ref) {
  return CompleteAction(ref.watch(actionRepositoryProvider));
});

// State providers
final actionsProvider =
    StateNotifierProvider<ActionsController, AsyncValue<List<ActionEntity>>>((
      ref,
    ) {
      return ActionsController(ref.watch(getActionsByTimeLeftUseCaseProvider));
    });

class ActionsController extends StateNotifier<AsyncValue<List<ActionEntity>>> {
  final GetActionsByTimeLeft _getActionsByTimeLeft;

  ActionsController(this._getActionsByTimeLeft)
    : super(const AsyncValue.loading()) {
    loadActions();
  }

  Future<void> loadActions() async {
    state = const AsyncValue.loading();
    try {
      final allActions = await _getActionsByTimeLeft();
      // Filter out payment actions - they go to payments section
      final filteredActions = allActions
          .where(
            (action) =>
                action.type != ActionType.payment && action.dueDate != null,
          ) // Only show actions with deadlines
          .toList();
      state = AsyncValue.data(filteredActions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadActions();
  }
}
