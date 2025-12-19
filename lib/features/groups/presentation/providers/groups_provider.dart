import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/usecases/get_user_groups.dart';
import '../../domain/usecases/get_archived_groups.dart';
import '../../domain/usecases/search_groups.dart';
import '../../domain/usecases/leave_group.dart';
import '../../domain/usecases/archive_group.dart';
import '../../domain/usecases/toggle_group_mute.dart';
import '../../domain/usecases/toggle_group_pin.dart';
import '../../domain/usecases/toggle_group_archive.dart';
import '../../data/fakes/fake_group_repository.dart';
import '../../domain/usecases/get_group_members.dart';
import '../../domain/entities/group_member_entity.dart';

// Repository provider - por padrão usa fake
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return FakeGroupRepository();
});

// Use cases providers
final getUserGroupsProvider = Provider<GetUserGroups>((ref) {
  return GetUserGroups(ref.watch(groupRepositoryProvider));
});

final getArchivedGroupsProvider = Provider<GetArchivedGroups>((ref) {
  return GetArchivedGroups(ref.watch(groupRepositoryProvider));
});

final searchGroupsProvider = Provider<SearchGroups>((ref) {
  return SearchGroups(ref.watch(groupRepositoryProvider));
});

final leaveGroupProvider = Provider<LeaveGroup>((ref) {
  return LeaveGroup(ref.watch(groupRepositoryProvider));
});

final archiveGroupProvider = Provider<ArchiveGroup>((ref) {
  return ArchiveGroup(ref.watch(groupRepositoryProvider));
});

final toggleGroupMuteProvider = Provider<ToggleGroupMute>((ref) {
  return ToggleGroupMute(ref.watch(groupRepositoryProvider));
});

final toggleGroupPinProvider = Provider<ToggleGroupPin>((ref) {
  return ToggleGroupPin(ref.watch(groupRepositoryProvider));
});

final toggleGroupArchiveProvider = Provider<ToggleGroupArchive>((ref) {
  return ToggleGroupArchive(ref.watch(groupRepositoryProvider));
});

// ✅ ADICIONAR: Use case provider para membros (NÍVEL GLOBAL)
final getGroupMembersUseCaseProvider = Provider<GetGroupMembers>((ref) {
  return GetGroupMembers(ref.watch(groupRepositoryProvider));
});

// ✅ ADICIONAR: State provider para membros (NÍVEL GLOBAL)
final groupMembersProvider = StateNotifierProvider.family<
    GroupMembersController, AsyncValue<List<GroupMemberEntity>>, String>((
  ref,
  groupId,
) {
  return GroupMembersController(
    ref.watch(getGroupMembersUseCaseProvider),
    groupId,
  );
});

// QR Code save provider
final saveGroupQrCodeProvider = Provider<Future<void> Function(String, String)>((ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return (String groupId, String qrCodeData) async {
    return await repository.saveGroupQrCode(groupId, qrCodeData);
  };
});

// Provider para converter photoPath em URL
final groupCoverUrlProvider = FutureProvider.family<String?, (String?, DateTime?)>((ref, params) async {
  final (photoPath, photoUpdatedAt) = params;
  
  if (photoPath == null || photoPath.isEmpty) {
    return null;
  }
  
  final repository = ref.watch(groupRepositoryProvider);
  return await repository.getGroupCoverUrl(photoPath, photoUpdatedAt);
});

// Groups state provider
final groupsProvider = FutureProvider<List<Group>>((ref) async {
  final getUserGroups = ref.watch(getUserGroupsProvider);
  return await getUserGroups.call();
});

// Archived groups provider
final archivedGroupsProvider = FutureProvider<List<Group>>((ref) async {
  final getArchivedGroups = ref.watch(getArchivedGroupsProvider);
  return await getArchivedGroups.call();
});

// Search provider
final groupsSearchProvider = FutureProvider.family<List<Group>, String>((
  ref,
  query,
) async {
  final searchGroups = ref.watch(searchGroupsProvider);
  return await searchGroups.call(query);
});

// Controller para ações de grupos
final groupsControllerProvider = Provider<GroupsController>((ref) {
  return GroupsController(ref);
});

// ✅ ADICIONAR: Controller para membros (NÍVEL GLOBAL)
class GroupMembersController
    extends StateNotifier<AsyncValue<List<GroupMemberEntity>>> {
  final GetGroupMembers _getGroupMembers;
  final String _groupId;

  GroupMembersController(this._getGroupMembers, this._groupId)
      : super(const AsyncValue.loading()) {
    loadMembers();
  }

  Future<void> loadMembers() async {
    state = const AsyncValue.loading();
    try {
      final members = await _getGroupMembers(_groupId);
      state = AsyncValue.data(members);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadMembers();
  }
}

class GroupsController {
  final Ref _ref;

  GroupsController(this._ref);

  /// Leave group with optimistic UI update
  /// Returns true if successful, false if failed (for rollback)
  Future<bool> leaveGroupOptimistic(String groupId) async {
    try {
      // 1. OPTIMISTIC UPDATE - immediately refresh to remove group from list
      _ref.invalidate(groupsProvider);
      _ref.invalidate(archivedGroupsProvider);
      
      // 2. SERVER UPDATE - execute in background
      final leaveGroup = _ref.read(leaveGroupProvider);
      await leaveGroup.call(groupId);
      
      // 3. SUCCESS - group removed from server
      return true;
    } catch (e) {
      // 4. ROLLBACK - refresh to restore group in list
      _ref.invalidate(groupsProvider);
      _ref.invalidate(archivedGroupsProvider);
      rethrow;
    }
  }

  Future<void> leaveGroup(String groupId) async {
    final leaveGroup = _ref.read(leaveGroupProvider);
    await leaveGroup.call(groupId);
    _ref.invalidate(groupsProvider);
    _ref.invalidate(archivedGroupsProvider);
  }

  Future<void> archiveGroup(String groupId) async {
    final archiveGroup = _ref.read(archiveGroupProvider);
    await archiveGroup.call(groupId);
    _ref.invalidate(groupsProvider);
    _ref.invalidate(archivedGroupsProvider);
  }

  Future<void> toggleMute(String groupId, bool isMuted) async {
    final toggleMute = _ref.read(toggleGroupMuteProvider);
    await toggleMute.call(groupId, isMuted);
    _ref.invalidate(groupsProvider);
    _ref.invalidate(archivedGroupsProvider);
  }

  Future<void> togglePin(String groupId) async {
    final togglePin = _ref.read(toggleGroupPinProvider);
    await togglePin.call(groupId);
    _ref.invalidate(groupsProvider);
    _ref.invalidate(archivedGroupsProvider);
  }

  Future<void> toggleArchive(String groupId) async {
    final toggleArchive = _ref.read(toggleGroupArchiveProvider);
    await toggleArchive.call(groupId);
    _ref.invalidate(groupsProvider);
    _ref.invalidate(archivedGroupsProvider);
  }

  void refreshGroups() {
    _ref.invalidate(groupsProvider);
    _ref.invalidate(archivedGroupsProvider);
  }
}