import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/action.dart';
import '../../domain/repositories/action_repository.dart';
import '../../domain/usecases/get_user_actions.dart';
import '../../data/fakes/fake_action_repository.dart';

// Repository provider - defaults to fake, overridden in main.dart for real
final actionRepositoryProvider = Provider<ActionRepository>((ref) {
  return FakeActionRepository();
});

// Use case providers
final getUserActionsUseCaseProvider = Provider<GetUserActions>((ref) {
  return GetUserActions(ref.watch(actionRepositoryProvider));
});

final dismissActionUseCaseProvider = Provider<DismissAction>((ref) {
  return DismissAction(ref.watch(actionRepositoryProvider));
});

// State provider
final actionsProvider =
    StateNotifierProvider<ActionsController, AsyncValue<List<ActionEntity>>>((
  ref,
) {
  return ActionsController(ref.watch(getUserActionsUseCaseProvider));
});

class ActionsController extends StateNotifier<AsyncValue<List<ActionEntity>>> {
  final GetUserActions _getUserActions;

  ActionsController(this._getUserActions) : super(const AsyncValue.loading()) {
    loadActions();
  }

  Future<void> loadActions() async {
    state = const AsyncValue.loading();
    try {
      final actions = await _getUserActions();
      state = AsyncValue.data(actions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadActions();
  }
}
