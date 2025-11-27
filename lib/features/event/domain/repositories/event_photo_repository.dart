import 'dart:io';

/// Repository interface for event photo operations
/// Handles photo uploads to events in Living and Recap states
abstract class EventPhotoRepository {
  /// Upload a photo to an event
  /// 
  /// - [eventId]: ID of the event to upload photo to
  /// - [groupId]: ID of the group (for storage path organization)
  /// - [imageFile]: The image file to upload
  /// - [capturedAt]: When the photo was captured (defaults to now)
  /// 
  /// Returns the uploaded photo URL on success
  /// Throws exception on failure
  Future<String> uploadPhoto({
    required String eventId,
    required String groupId,
    required File imageFile,
    DateTime? capturedAt,
  });

  /// Delete a photo from an event
  /// 
  /// Only the uploader or event host can delete photos
  Future<void> deletePhoto({
    required String photoId,
    required String storagePath,
  });

  /// Get signed URL for a photo (for private bucket access)
  Future<String> getSignedPhotoUrl(String storagePath);
}
