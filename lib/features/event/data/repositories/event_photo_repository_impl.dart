import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../domain/repositories/event_photo_repository.dart';
import '../data_sources/event_photo_data_source.dart';
import '../../../../shared/utils/image_compression_service.dart';

/// Implementation of EventPhotoRepository using Supabase
/// Handles photo compression before upload
class EventPhotoRepositoryImpl implements EventPhotoRepository {
  final EventPhotoDataSource _dataSource;

  EventPhotoRepositoryImpl(this._dataSource);

  @override
  Future<String> uploadPhoto({
    required String eventId,
    required String groupId,
    required File imageFile,
    DateTime? capturedAt,
  }) async {
    try {
      print('📸 Starting photo upload for event: $eventId');

      // 1. Compress image before upload (reduce size for faster upload and storage)
      print('🗜️ Compressing image...');
      final xFile = XFile(imageFile.path);
      final compressedBytes = await ImageCompressionService.compressToWebP(xFile);

      // Create temporary file with compressed bytes
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressedBytes);

      print('✅ Image compressed: ${imageFile.lengthSync()} bytes → ${compressedBytes.length} bytes');

      // 2. Upload compressed image via data source
      final photoData = await _dataSource.uploadPhoto(
        eventId: eventId,
        groupId: groupId,
        imageFile: tempFile,
        capturedAt: capturedAt ?? DateTime.now(),
      );

      // 3. Clean up temporary compressed file
      await tempFile.delete();
      print('🧹 Cleaned up temporary compressed file');

      // 4. Return photo URL
      final photoUrl = photoData['url'] as String;
      print('✅ Photo uploaded successfully: $photoUrl');

      return photoUrl;
    } catch (e, stackTrace) {
      print('❌ Error in repository uploadPhoto: $e');
      print(stackTrace);
      throw Exception('Failed to upload photo: $e');
    }
  }

  @override
  Future<void> deletePhoto({
    required String photoId,
    required String storagePath,
  }) async {
    try {
      await _dataSource.deletePhoto(
        photoId: photoId,
        storagePath: storagePath,
      );
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  @override
  Future<String> getSignedPhotoUrl(String storagePath) async {
    try {
      return await _dataSource.getSignedUrl(storagePath);
    } catch (e) {
      throw Exception('Failed to get signed photo URL: $e');
    }
  }
}
