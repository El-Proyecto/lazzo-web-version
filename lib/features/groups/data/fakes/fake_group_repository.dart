import '../../domain/entities/group.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/group_repository.dart';
import '../../../../shared/models/group_enums.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/group_member_entity.dart';

/// Implementação fake do repositório de grupos para desenvolvimento
class FakeGroupRepository implements GroupRepository {
  // MOCK CONTROL VARIABLE for testing no-groups empty state
  // Change this to test different scenarios:
  // true = return empty groups list (simulates user with no groups)
  // false = return normal mock groups (default)
  // IMPORTANT: After changing this, you MUST do Hot Restart (not Hot Reload)
  static bool mockNoGroups = false;

  final List<GroupEntity> _createdGroups = [];
  final List<Group> _mockGroups = [
    Group(
      id: '1',
      name: 'Obama Care',
      photoPath: 'groups/1/cover_1.webp',
      photoUpdatedAt: DateTime.now().subtract(const Duration(days: 1)),
      lastActivity: 'Decide date · closes Tuesday',
      lastActivityTime: DateTime.now().subtract(const Duration(minutes: 30)),
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
      photoPath: 'groups/2/cover_2.webp',
      photoUpdatedAt: DateTime.now().subtract(const Duration(hours: 2)),
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
      photoPath: 'groups/3/cover_3.webp',
      photoUpdatedAt: DateTime.now().subtract(const Duration(hours: 4)),
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
      photoPath: 'groups/4/cover_4.webp',
      photoUpdatedAt: DateTime.now().subtract(const Duration(days: 2)),
      lastActivity: 'Last event: Piquenique na praia',
      lastActivityTime: DateTime.now().subtract(const Duration(days: 2)),
      unreadCount: 1,
      openActionsCount: null,
      addPhotosCount: null,
      addPhotosTimeLeft: null,
      status: GroupStatus.active,
      memberCount: 5,
    ),
    const Group(
      id: '5',
      name: 'Work Team',
      photoPath: null, // sem foto
      photoUpdatedAt: null,
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
      photoPath: 'groups/6/cover_6.webp',
      photoUpdatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      lastActivity: 'Vote a place · 3 options',
      lastActivityTime: DateTime.now().subtract(const Duration(hours: 2)),
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
      photoPath: 'groups/7/cover_7.webp',
      photoUpdatedAt: DateTime.now(),
      lastActivity: 'Live now · ends in 1h 20m',
      lastActivityTime: DateTime.now(),
      unreadCount: null,
      openActionsCount: null,
      addPhotosCount: null,
      addPhotosTimeLeft: null,
      status: GroupStatus.active,
      memberCount: 7,
    ),
    const Group(
      id: '8',
      name: 'Cooking Class',
      photoPath: null, // sem foto
      photoUpdatedAt: null,
      lastActivity: 'Memory ready to share',
      lastActivityTime: null,
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
      photoPath: 'groups/9/cover_9.webp',
      photoUpdatedAt: DateTime.now().subtract(const Duration(days: 30)),
      lastActivity: 'Project completed',
      lastActivityTime: DateTime.now().subtract(const Duration(days: 30)),
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
      photoPath: 'groups/10/cover_10.webp',
      photoUpdatedAt: DateTime.now().subtract(const Duration(days: 60)),
      lastActivity: 'Memories saved',
      lastActivityTime: DateTime.now().subtract(const Duration(days: 60)),
      unreadCount: null,
      openActionsCount: null,
      addPhotosCount: null,
      addPhotosTimeLeft: null,
      status: GroupStatus.archived,
      memberCount: 15,
    ),
  ];

  int _nextId = 11;

  @override
  Future<List<Group>> getUserGroups() async {
    // Simular delay da rede
    await Future.delayed(const Duration(milliseconds: 500));

    // Check mock control variable
    if (mockNoGroups) {
      return []; // Return empty list to simulate user with no groups
    }

    // Retorna apenas grupos não arquivados
    return _mockGroups
        .where((group) => group.status != GroupStatus.archived)
        .toList();
  }

  @override
  Future<List<Group>> getArchivedGroups() async {
    // Simular delay da rede
    await Future.delayed(const Duration(milliseconds: 500));
    // Retorna apenas grupos arquivados
    return _mockGroups
        .where((group) => group.status == GroupStatus.archived)
        .toList();
  }

  @override
  Future<List<Group>> searchGroups(String searchTerm) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockGroups
        .where(
          (group) =>
              group.name.toLowerCase().contains(searchTerm.toLowerCase()),
        )
        .toList();
  }

  @override
  Future<Group?> getGroupById(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _mockGroups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Group> createGroup({
    required String name,
    String? photoPath, // atualizado de avatarUrl para photoPath
    List<String>? memberIds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final newGroup = Group(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      photoPath: photoPath, // usando photoPath
      lastActivity: 'No events — create one',
      addPhotosTimeLeft: null,
      status: GroupStatus.active,
      memberCount: (memberIds?.length ?? 0) + 1, // +1 for creator
    );

    _mockGroups.insert(0, newGroup);
    return newGroup;
  }

  @override
  Future<GroupEntity> createGroupEntity(GroupEntity group) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final createdGroup = group.copyWith(
      id: 'fake_group_${_nextId++}',
      createdAt: DateTime.now(),
    );

    _createdGroups.add(createdGroup);
    return createdGroup;
  }

  @override
  Future<void> inviteMembers(String groupId, List<String> memberIds) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Simular convite de membros
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Simula remoção do grupo da lista do usuário
    // (no fake, assumimos que o usuário sempre deixa o grupo, e o grupo é removido da sua lista)
    final removedCount =
        _mockGroups.where((group) => group.id == groupId).length;
    _mockGroups.removeWhere((group) => group.id == groupId);

    print(
        '🎭 [Fake] User left group $groupId - removed from user\'s list ($removedCount groups removed)');
  }

  @override
  Future<void> toggleMute(String groupId, bool isMuted) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mockGroups.indexWhere((group) => group.id == groupId);
    if (index != -1) {
      final group = _mockGroups[index];
      final updatedGroup = Group(
        id: group.id,
        name: group.name,
        photoPath: group.photoPath,
        photoUpdatedAt: group.photoUpdatedAt,
        lastActivity: group.lastActivity,
        lastActivityTime: group.lastActivityTime,
        unreadCount: group.unreadCount,
        openActionsCount: group.openActionsCount,
        addPhotosCount: group.addPhotosCount,
        addPhotosTimeLeft: group.addPhotosTimeLeft,
        status: group.status,
        isMuted: isMuted, // Definir o valor passado, não toggle
        isPinned: group.isPinned,
        memberCount: group.memberCount,
      );
      _mockGroups[index] = updatedGroup;
    }
  }

  @override
  Future<void> togglePin(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mockGroups.indexWhere((group) => group.id == groupId);
    if (index != -1) {
      final group = _mockGroups[index];
      final updatedGroup = Group(
        id: group.id,
        name: group.name,
        photoPath: group.photoPath,
        photoUpdatedAt: group.photoUpdatedAt,
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
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mockGroups.indexWhere((group) => group.id == groupId);
    if (index != -1) {
      final group = _mockGroups[index];
      final newStatus = group.status == GroupStatus.archived
          ? GroupStatus.active
          : GroupStatus.archived;

      final updatedGroup = Group(
        id: group.id,
        name: group.name,
        photoPath: group.photoPath,
        photoUpdatedAt: group.photoUpdatedAt,
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
    await Future.delayed(const Duration(milliseconds: 300));
    return ['current_user', 'marco', 'ana', 'joao'];
  }

  @override
  Future<List<GroupMemberEntity>> getGroupMembersEntities(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Mock members para teste
    return [
      const GroupMemberEntity(
        id: 'current_user',
        name: 'You',
        avatarUrl: null,
        role: 'admin',
      ),
      const GroupMemberEntity(
        id: 'marco',
        name: 'Marco',
        avatarUrl: 'https://i.pravatar.cc/150?u=marco',
        role: 'member',
      ),
      const GroupMemberEntity(
        id: 'ana',
        name: 'Ana',
        avatarUrl: 'https://i.pravatar.cc/150?u=ana',
        role: 'member',
      ),
      const GroupMemberEntity(
        id: 'joao',
        name: 'João',
        avatarUrl: 'https://i.pravatar.cc/150?u=joao',
        role: 'member',
      ),
    ];
  }

  @override
  Future<String> uploadGroupCoverPhoto(XFile imageFile, String groupId) async {
    // Simulate photo upload
    await Future.delayed(const Duration(seconds: 1));
    return 'groups/$groupId/cover_${DateTime.now().millisecondsSinceEpoch}.webp';
  }

  @override
  Future<String?> getGroupCoverUrl(
      String? photoPath, DateTime? photoUpdatedAt) async {
    if (photoPath == null || photoPath.isEmpty) {
      return null;
    }

    // Simulate signed URL generation
    await Future.delayed(const Duration(milliseconds: 200));

    // Mock signed URL with cache busting
    final timestamp = photoUpdatedAt?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    return 'https://mock-storage.example.com/$photoPath?signed=true&t=$timestamp';
  }

  @override
  Future<void> saveGroupQrCode(String groupId, String qrCodeData) async {
    // Simulate QR code save
    await Future.delayed(const Duration(milliseconds: 200));
    print('Mock: QR code saved for group $groupId: $qrCodeData');
  }
}
