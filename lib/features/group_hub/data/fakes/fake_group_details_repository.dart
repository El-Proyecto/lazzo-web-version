import '../../../groups/domain/entities/group_permissions.dart';
import '../../domain/entities/group_details_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../domain/repositories/group_details_repository.dart';

/// Fake repository for group details (for development/testing)
class FakeGroupDetailsRepository implements GroupDetailsRepository {
  @override
  Future<GroupDetailsEntity> getGroupDetails(String groupId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return const GroupDetailsEntity(
      id: '1',
      name: 'Amigos Feup',
      photoUrl: null,
      memberCount: 8,
      isCurrentUserAdmin: true,
      isMuted: false,
      permissions: GroupPermissions(
        membersCanInvite: true,
        membersCanAddMembers: false,
        membersCanCreateEvents: true,
      ),
    );
  }

  @override
  Future<List<GroupMemberEntity>> getGroupMembers(String groupId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return const [
      // Current user (always first)
      GroupMemberEntity(
        id: 'current_user',
        name: 'Current User',
        profileImageUrl: null,
        isAdmin: true,
        isCurrentUser: true,
      ),
      // Other admins
      GroupMemberEntity(
        id: '2',
        name: 'Marco Silva',
        profileImageUrl: null,
        isAdmin: true,
        isCurrentUser: false,
      ),
      GroupMemberEntity(
        id: '3',
        name: 'Ana Costa',
        profileImageUrl: null,
        isAdmin: true,
        isCurrentUser: false,
      ),
      // Regular members
      GroupMemberEntity(
        id: '4',
        name: 'João Santos',
        profileImageUrl: null,
        isAdmin: false,
        isCurrentUser: false,
      ),
      GroupMemberEntity(
        id: '5',
        name: 'Maria Oliveira',
        profileImageUrl: null,
        isAdmin: false,
        isCurrentUser: false,
      ),
      GroupMemberEntity(
        id: '6',
        name: 'Pedro Alves',
        profileImageUrl: null,
        isAdmin: false,
        isCurrentUser: false,
      ),
      GroupMemberEntity(
        id: '7',
        name: 'Sofia Martins',
        profileImageUrl: null,
        isAdmin: false,
        isCurrentUser: false,
      ),
      GroupMemberEntity(
        id: '8',
        name: 'Ricardo Ferreira',
        profileImageUrl: null,
        isAdmin: false,
        isCurrentUser: false,
      ),
    ];
  }

  @override
  Future<void> toggleMute(String groupId, bool isMuted) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    // In real implementation, this would update the backend
  }

  @override
  Future<void> updateMemberRole(String groupId, String userId, bool isAdmin) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Validate: cannot demote if this is the last admin (fake validation)
    if (!isAdmin) {
      // In a real scenario, this would check the actual member list
      // For fake, we just simulate the validation
      print('🔐 [FAKE] Updating role for user $userId to ${isAdmin ? "admin" : "member"}');
    }
    
    // In real implementation, this would update the backend
  }
}
