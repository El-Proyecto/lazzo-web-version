import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_permissions.dart';
import '../../domain/usecases/create_group.dart';
import 'groups_provider.dart'; // Import the shared provider

/// Provider for create group use case
final createGroupUseCaseProvider = Provider<CreateGroup>((ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return CreateGroup(repository);
});

/// Provider for create group state management
final createGroupProvider =
    StateNotifierProvider<CreateGroupController, AsyncValue<GroupEntity?>>((
  ref,
) {
  final useCase = ref.watch(createGroupUseCaseProvider);
  return CreateGroupController(useCase);
});

/// Controller for managing create group state
class CreateGroupController extends StateNotifier<AsyncValue<GroupEntity?>> {
  final CreateGroup _useCase;

  CreateGroupController(this._useCase) : super(const AsyncValue.data(null));

  /// Creates a new group with the provided parameters
  Future<void> createGroup({
    required String name,
    String? description,
    String? photoPath,
  }) async {
    state = const AsyncValue.loading();

    try {
      final groupEntity = GroupEntity(
        name: name,
        description: description,
        photoUrl: photoPath,
        permissions: const GroupPermissions(
          membersCanInvite: true,
          membersCanAddMembers: true,
          membersCanCreateEvents: true,
        ),
      );

      final createdGroup = await _useCase.call(groupEntity);
      state = AsyncValue.data(createdGroup);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}
