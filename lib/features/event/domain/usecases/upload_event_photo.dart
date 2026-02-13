import 'dart:io';
import '../repositories/event_photo_repository.dart';

/// Use case for uploading photos to events
/// Validates inputs and orchestrates photo upload
class UploadEventPhoto {
  final EventPhotoRepository _repository;

  UploadEventPhoto(this._repository);

  /// Upload a photo to an event
  ///
  /// Validates:
  /// - Event ID is not empty
  /// - Image file exists
  ///
  /// Returns the uploaded photo URL
  Future<String> call({
    required String eventId,
    required File imageFile,
    DateTime? capturedAt,
  }) async {
    // Validation
    if (eventId.isEmpty) {
      throw ArgumentError('Event ID cannot be empty');
    }

    if (!await imageFile.exists()) {
      throw ArgumentError('Image file does not exist');
    }

    // Upload photo via repository
    return await _repository.uploadPhoto(
      eventId: eventId,
      imageFile: imageFile,
      capturedAt: capturedAt ?? DateTime.now(),
    );
  }
}
