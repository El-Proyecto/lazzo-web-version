import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/update_group_repository.dart';
import '../../domain/usecases/update_group.dart';
import '../../data/fakes/fake_update_group_repository.dart';

/// Provider for update group repository
final updateGroupRepositoryProvider = Provider<UpdateGroupRepository>((ref) {
  return FakeUpdateGroupRepository();
});

/// Provider for update group use case
final updateGroupUseCaseProvider = Provider<UpdateGroup>((ref) {
  final repository = ref.watch(updateGroupRepositoryProvider);
  return UpdateGroup(repository);
});

/// Provider for update group state management
final updateGroupProvider =
    StateNotifierProvider<UpdateGroupController, AsyncValue<GroupEntity?>>((
  ref,
) {
  final useCase = ref.watch(updateGroupUseCaseProvider);
  return UpdateGroupController(useCase);
});

/// Controller for managing update group state
class UpdateGroupController extends StateNotifier<AsyncValue<GroupEntity?>> {
  final UpdateGroup _useCase;

  UpdateGroupController(this._useCase) : super(const AsyncValue.data(null));

  /// Updates an existing group with the provided parameters
  Future<void> updateGroup({
    required String groupId,
    required String name,
    String? description,
    String? photoPath,
    required bool canEditSettings,
    required bool canAddMembers,
    required bool canSendMessages,
  }) async {
    state = const AsyncValue.loading();

    try {
      final updatedGroup = await _useCase.call(
        groupId: groupId,
        name: name,
        description: description,
        photoPath: photoPath,
        canEditSettings: canEditSettings,
        canAddMembers: canAddMembers,
        canSendMessages: canSendMessages,
      );
      state = AsyncValue.data(updatedGroup);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Reset state to allow editing another group
  void reset() {
    state = const AsyncValue.data(null);
  }
}
