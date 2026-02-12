import '../entities/other_profile_entity.dart';

/// Repository interface for other user profiles
/// Defines methods for fetching other user data
abstract class OtherProfileRepository {
  /// Get another user's profile by ID
  /// Returns profile with shared events and memories
  Future<OtherProfileEntity> getOtherUserProfile(String userId);

  // LAZZO 2.0: Group invite methods removed (getInvitableGroups, inviteToGroup, acceptGroupInvite, declineGroupInvite)
}
