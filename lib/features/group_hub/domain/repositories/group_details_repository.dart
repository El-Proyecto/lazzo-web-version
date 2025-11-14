import '../entities/group_details_entity.dart';
import '../entities/group_member_entity.dart';

/// Repository interface for group details operations
abstract class GroupDetailsRepository {
  /// Get group details by group ID
  Future<GroupDetailsEntity> getGroupDetails(String groupId);

  /// Get all members of a group
  Future<List<GroupMemberEntity>> getGroupMembers(String groupId);

  /// Toggle mute/unmute for a group
  Future<void> toggleMute(String groupId, bool isMuted);
}
