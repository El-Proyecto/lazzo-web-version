import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';
import '../../../../shared/models/group_enums.dart';

/// Implementação fake do repositório de grupos para desenvolvimento
class FakeGroupRepository implements GroupRepository {
  final List<Group> _mockGroups = [
    Group(
      id: '1',
      name: 'Obama Care',
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
      lastActivity: 'Decide date · closes Tuesday',
      lastActivityTime: DateTime.now().subtract(Duration(minutes: 30)),
      unreadCount: 2,
      openActionsCount: 3,
      addPhotosCount: null,
      addPhotosTimeLeft: null,
      status: GroupStatus.active,
      isPinned: true, // Grupo afixado
      memberCount: 8,
    ),
    Group(
      id: '2',
      name: 'Beach Volleyball',
      avatarUrl: 'https://i.pravatar.cc/150?img=2',
      lastActivity: 'Add photos · 2h left',
      lastActivityTime: null,
      unreadCount: null,
      openActionsCount: 2,
      addPhotosCount: 5,
      addPhotosTimeLeft: '2h',
      status: GroupStatus.active,
      isPinned: false,
      memberCount: 12,
    ),
    Group(
      id: '3',
      name: 'Study Group',
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      lastActivity: 'Add photos · 4h left',
      lastActivityTime: null,
      unreadCount: null,
      openActionsCount: null,
      addPhotosCount: 3,
      addPhotosTimeLeft: '4h',
      status: GroupStatus.active,
      memberCount: 6,
    ),
    Group(
      id: '4',
      name: 'Family',
      avatarUrl: 'https://i.pravatar.cc/150?img=4',
      lastActivity: 'Last event: Piquenique na praia',
      lastActivityTime: DateTime.now().subtract(Duration(days: 2)),
      unreadCount: 1,
      openActionsCount: null,
      addPhotosCount: null,
      addPhotosTimeLeft: null,
      status: GroupStatus.active,
      memberCount: 5,
    ),
    Group(
      id: '5',
      name: 'Work Team',
      avatarUrl: null,
      lastActivity: 'No events — create one',
      lastActivityTime: null,
      unreadCount: null,
      openActionsCount: null,
      addPhotosCount: null,
      addPhotosTimeLeft: null,
      status: GroupStatus.active,
      isMuted: true, // Grupo mutado para teste
      memberCount: 15,
    ),
    Group(
      id: '6',
      name: 'Weekend Warriors',
      avatarUrl: 'https://i.pravatar.cc/150?img=6',
      lastActivity: 'Vote a place · 3 options',
      lastActivityTime: DateTime.now().subtract(Duration(hours: 2)),
      unreadCount: 3,
      openActionsCount: 2,
      addPhotosCount: null,
      addPhotosTimeLeft: null,
      status: GroupStatus.active,
      isPinned: true, // Grupo pinned e muted para testar os dois ícones
      isMuted: true,
      memberCount: 10,
    ),
    Group(
      id: '7',
      name: 'Hiking Squad',
      avatarUrl: 'https://i.pravatar.cc/150?img=7',
      lastActivity: 'Live now · ends in 1h 20m',
      lastActivityTime: DateTime.now(),
      unreadCount: null,
      openActionsCount: null,
      addPhotosCount: null,
      addPhotosTimeLeft: null,
      status: GroupStatus.active,
      memberCount: 7,
    ),
    Group(
      id: '8',
      name: 'Cooking Class',
      avatarUrl: null,
      lastActivity: 'Memory ready to share',
      lastActivityTime: DateTime.now().subtract(Duration(hours: 6)),
      unreadCount: null,
      openActionsCount: null,
      addPhotosCount: 1,
      addPhotosTimeLeft: '4h',
      status: GroupStatus.active,
      memberCount: 9,
    ),
    Group(
      id: '9',
      name: 'Old Project',
      avatarUrl: 'https://i.pravatar.cc/150?img=9',
      lastActivity: 'Project completed',
      lastActivityTime: DateTime.now().subtract(Duration(days: 30)),
      unreadCount: null,
      openActionsCount: null,
      addPhotosCount: null,
      addPhotosTimeLeft: null,
      status: GroupStatus.archived,
      memberCount: 5,
    ),
    Group(
      id: '10',
      name: 'Summer Camp 2024',
      avatarUrl: 'https://i.pravatar.cc/150?img=10',
      lastActivity: 'Memories saved',
      lastActivityTime: DateTime.now().subtract(Duration(days: 60)),
      unreadCount: null,
      openActionsCount: null,
      addPhotosCount: null,
      addPhotosTimeLeft: null,
      status: GroupStatus.archived,
      memberCount: 15,
    ),
  ];

  @override
  Future<List<Group>> getUserGroups() async {
    // Simular delay da rede
    await Future.delayed(Duration(milliseconds: 500));
    return List.from(_mockGroups);
  }

  @override
  Future<List<Group>> searchGroups(String searchTerm) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockGroups
        .where(
          (group) =>
              group.name.toLowerCase().contains(searchTerm.toLowerCase()),
        )
        .toList();
  }

  @override
  Future<Group?> getGroupById(String groupId) async {
    await Future.delayed(Duration(milliseconds: 200));
    try {
      return _mockGroups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Group> createGroup({
    required String name,
    String? avatarUrl,
    List<String>? memberIds,
  }) async {
    await Future.delayed(Duration(milliseconds: 800));

    final newGroup = Group(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      avatarUrl: avatarUrl,
      lastActivity: 'No events — create one',
      addPhotosTimeLeft: null,
      status: GroupStatus.active,
      memberCount: (memberIds?.length ?? 0) + 1, // +1 for creator
    );

    _mockGroups.insert(0, newGroup);
    return newGroup;
  }

  @override
  Future<void> inviteMembers(String groupId, List<String> memberIds) async {
    await Future.delayed(Duration(milliseconds: 600));
    // Simular convite de membros
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    await Future.delayed(Duration(milliseconds: 400));
    _mockGroups.removeWhere((group) => group.id == groupId);
  }

  @override
  Future<void> toggleMute(String groupId, bool isMuted) async {
    await Future.delayed(Duration(milliseconds: 300));

    final index = _mockGroups.indexWhere((group) => group.id == groupId);
    if (index != -1) {
      final group = _mockGroups[index];
      final updatedGroup = Group(
        id: group.id,
        name: group.name,
        avatarUrl: group.avatarUrl,
        lastActivity: group.lastActivity,
        lastActivityTime: group.lastActivityTime,
        unreadCount: group.unreadCount,
        openActionsCount: group.openActionsCount,
        addPhotosCount: group.addPhotosCount,
        addPhotosTimeLeft: group.addPhotosTimeLeft,
        status: group.status,
        isMuted: !group.isMuted, // Toggle mute status
        isPinned: group.isPinned,
        memberCount: group.memberCount,
      );
      _mockGroups[index] = updatedGroup;
    }
  }

  @override
  Future<void> togglePin(String groupId) async {
    await Future.delayed(Duration(milliseconds: 300));

    final index = _mockGroups.indexWhere((group) => group.id == groupId);
    if (index != -1) {
      final group = _mockGroups[index];
      final updatedGroup = Group(
        id: group.id,
        name: group.name,
        avatarUrl: group.avatarUrl,
        lastActivity: group.lastActivity,
        lastActivityTime: group.lastActivityTime,
        unreadCount: group.unreadCount,
        openActionsCount: group.openActionsCount,
        addPhotosCount: group.addPhotosCount,
        addPhotosTimeLeft: group.addPhotosTimeLeft,
        status: group.status,
        isMuted: group.isMuted,
        isPinned: !group.isPinned, // Toggle pin status
        memberCount: group.memberCount,
      );
      _mockGroups[index] = updatedGroup;
    }
  }

  @override
  Future<void> toggleArchive(String groupId) async {
    await Future.delayed(Duration(milliseconds: 300));

    final index = _mockGroups.indexWhere((group) => group.id == groupId);
    if (index != -1) {
      final group = _mockGroups[index];
      final newStatus = group.status == GroupStatus.archived
          ? GroupStatus.active
          : GroupStatus.archived;

      final updatedGroup = Group(
        id: group.id,
        name: group.name,
        avatarUrl: group.avatarUrl,
        lastActivity: group.lastActivity,
        lastActivityTime: group.lastActivityTime,
        unreadCount: group.unreadCount,
        openActionsCount: group.openActionsCount,
        addPhotosCount: group.addPhotosCount,
        addPhotosTimeLeft: group.addPhotosTimeLeft,
        status: newStatus,
        isMuted: group.isMuted,
        // Remove pinned status when archiving
        isPinned: newStatus == GroupStatus.archived ? false : group.isPinned,
        memberCount: group.memberCount,
      );
      _mockGroups[index] = updatedGroup;
    }
  }

  @override
  Future<List<String>> getGroupMembers(String groupId) async {
    await Future.delayed(Duration(milliseconds: 400));
    // Retornar lista mock de IDs de membros
    return ['user1', 'user2', 'user3'];
  }
}
