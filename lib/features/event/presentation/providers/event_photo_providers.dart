import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/usecases/upload_event_photo.dart';
import 'event_providers.dart';

/// Provider for photo upload functionality
/// Exposes methods to pick and upload photos from camera or gallery
class EventPhotoUploadNotifier extends StateNotifier<AsyncValue<String?>> {
  final UploadEventPhoto _uploadEventPhoto;
  final ImagePicker _imagePicker;

  EventPhotoUploadNotifier(
    this._uploadEventPhoto,
    this._imagePicker,
  ) : super(const AsyncValue.data(null));

  /// Pick and upload a photo from camera
  Future<void> takePhoto({
    required String eventId,
    required String groupId,
  }) async {
    try {
      print('📸 Opening camera...');

      // Pick image from camera
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo == null) {
        print('⚠️ User cancelled camera');
        return;
      }

      print('✅ Photo captured: ${photo.path}');

      // Upload photo
      await _uploadPhoto(
        eventId: eventId,
        groupId: groupId,
        imageFile: File(photo.path),
      );
    } catch (error, stackTrace) {
      print('❌ Error taking photo: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Pick and upload a photo from gallery
  Future<void> pickPhotoFromGallery({
    required String eventId,
    required String groupId,
  }) async {
    try {
      print('🖼️ Opening gallery...');

      // Pick image from gallery
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo == null) {
        print('⚠️ User cancelled gallery picker');
        return;
      }

      print('✅ Photo selected: ${photo.path}');

      // Upload photo
      await _uploadPhoto(
        eventId: eventId,
        groupId: groupId,
        imageFile: File(photo.path),
      );
    } catch (error, stackTrace) {
      print('❌ Error picking photo from gallery: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Internal method to upload photo
  Future<void> _uploadPhoto({
    required String eventId,
    required String groupId,
    required File imageFile,
  }) async {
    state = const AsyncValue.loading();

    try {
      print('📤 Uploading photo...');

      final photoUrl = await _uploadEventPhoto(
        eventId: eventId,
        groupId: groupId,
        imageFile: imageFile,
      );

      print('✅ Photo uploaded successfully: $photoUrl');

      state = AsyncValue.data(photoUrl);
    } catch (error, stackTrace) {
      print('❌ Error uploading photo: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for UploadEventPhoto use case
final uploadEventPhotoProvider = Provider<UploadEventPhoto>((ref) {
  final repository = ref.watch(eventPhotoRepositoryProvider);
  return UploadEventPhoto(repository);
});

/// Provider for ImagePicker instance
final imagePickerProvider = Provider<ImagePicker>((ref) {
  return ImagePicker();
});

/// StateNotifier provider for photo upload
final eventPhotoUploadNotifierProvider = StateNotifierProvider.family<
    EventPhotoUploadNotifier,
    AsyncValue<String?>,
    String>((ref, eventId) {
  final uploadUseCase = ref.watch(uploadEventPhotoProvider);
  final imagePicker = ref.watch(imagePickerProvider);

  return EventPhotoUploadNotifier(uploadUseCase, imagePicker);
});
