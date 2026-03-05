import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../services/analytics_service.dart';
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
  }) async {
    try {
      // Track photo upload started
      AnalyticsService.track('photo_upload_started', properties: {
        'event_id': eventId,
        'source': 'camera',
        'platform': 'ios',
      });
      // Pick image from camera
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo == null) {
        return;
      }

      // Upload photo
      await _uploadPhoto(
        eventId: eventId,
        imageFile: File(photo.path),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Pick and upload photos from gallery (supports multi-selection)
  Future<void> pickPhotoFromGallery({
    required String eventId,
  }) async {
    try {
      // Track photo upload started
      AnalyticsService.track('photo_upload_started', properties: {
        'event_id': eventId,
        'source': 'gallery',
        'platform': 'ios',
      });
      // Pick multiple images from gallery (native multi-select on iOS/Android)
      final List<XFile> photos = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photos.isEmpty) {
        return;
      }

      // Limit to 10 photos per batch
      final limitedPhotos = photos.take(10).toList();

      // Upload all selected photos sequentially
      state = const AsyncValue.loading();
      String? lastUrl;
      for (final photo in limitedPhotos) {
        lastUrl = await _uploadPhotoFile(
          eventId: eventId,
          imageFile: File(photo.path),
        );
      }

      state = AsyncValue.data(lastUrl);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Internal method to upload a single photo file and return URL
  Future<String> _uploadPhotoFile({
    required String eventId,
    required File imageFile,
  }) async {
    final stopwatch = Stopwatch()..start();
    final fileSizeKb = (await imageFile.length()) ~/ 1024;

    final photoUrl = await _uploadEventPhoto(
      eventId: eventId,
      imageFile: imageFile,
    );

    stopwatch.stop();

    // Track photo upload with METRICS.md-required properties
    AnalyticsService.track('photo_uploaded', properties: {
      'event_id': eventId,
      'upload_duration_ms': stopwatch.elapsedMilliseconds,
      'file_size_kb': fileSizeKb,
      'is_cover': false,
      'platform': 'ios',
    });

    return photoUrl;
  }

  /// Internal method to upload photo
  Future<void> _uploadPhoto({
    required String eventId,
    required File imageFile,
  }) async {
    state = const AsyncValue.loading();
    final stopwatch = Stopwatch()..start();

    try {
      // Get file size before upload
      final fileSizeKb = (await imageFile.length()) ~/ 1024;

      final photoUrl = await _uploadEventPhoto(
        eventId: eventId,
        imageFile: imageFile,
      );

      stopwatch.stop();
      state = AsyncValue.data(photoUrl);

      // Track photo upload with METRICS.md-required properties
      AnalyticsService.track('photo_uploaded', properties: {
        'event_id': eventId,
        'upload_duration_ms': stopwatch.elapsedMilliseconds,
        'file_size_kb': fileSizeKb,
        'is_cover': false,
        'platform': 'ios',
      });
    } catch (error, stackTrace) {
      stopwatch.stop();
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
    EventPhotoUploadNotifier, AsyncValue<String?>, String>((ref, eventId) {
  final uploadUseCase = ref.watch(uploadEventPhotoProvider);
  final imagePicker = ref.watch(imagePickerProvider);

  return EventPhotoUploadNotifier(uploadUseCase, imagePicker);
});

/// Provider to get all photos for an event
final eventPhotosProvider =
    FutureProvider.family<List<dynamic>, String>((ref, eventId) async {
  final repository = ref.watch(eventPhotoRepositoryProvider);
  return await repository.getEventPhotos(eventId);
});
