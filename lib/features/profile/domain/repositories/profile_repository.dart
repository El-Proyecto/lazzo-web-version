import '../entities/profile_entity.dart';
import 'package:image_picker/image_picker.dart';

/// Abstract repository interface for profile operations
/// Defines contracts for profile data access
abstract class ProfileRepository {
  /// Get current user's profile
  Future<ProfileEntity> getCurrentUserProfile();

  /// Get profile by user ID
  Future<ProfileEntity> getProfileById(String userId);

  /// Update current user's profile
  Future<ProfileEntity> updateProfile(ProfileEntity profile);

  /// Get user's memories
  Future<List<MemoryEntity>> getUserMemories(String userId);

  /// Upload profile picture
  Future<String> uploadProfilePicture(XFile imageFile);

  /// Get signed URL for profile picture (since bucket is private)
  Future<String?> getProfilePictureUrl(String? avatarUrl);

  /// Delete profile picture
  Future<void> deleteProfilePicture();
}
