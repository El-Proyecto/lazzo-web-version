import '../entities/other_profile_entity.dart';
import '../entities/invite_group_entity.dart';

/// Repository interface for other user profiles
/// Defines methods for fetching other user data and inviting to groups
abstract class OtherProfileRepository {
  /// Get another user's profile by ID
  /// Returns profile with shared events and memories
  Future<OtherProfileEntity> getOtherUserProfile(String userId);

  /// Get list of groups where current user can invite this person
  /// Only returns groups where current user is member and other user is not
  Future<List<InviteGroupEntity>> getInvitableGroups(String userId);

  /// Send group invitation to user
  /// Returns true if invitation was sent successfully
  Future<bool> inviteToGroup({
    required String userId,
    required String groupId,
  });

  /// Accept a group invite
  /// Returns true if invite was accepted successfully
  Future<bool> acceptGroupInvite({
    required String userId,
    required String groupId,
  });

  /// Decline a group invite
  /// Returns true if invite was declined successfully
  Future<bool> declineGroupInvite({
    required String userId,
    required String groupId,
  });
}
