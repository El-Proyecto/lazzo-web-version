import '../../domain/entities/memory_entity.dart';
import '../../domain/repositories/memory_repository.dart';
import '../data_sources/memory_data_source.dart';
import '../data_sources/memory_photo_data_source.dart';
import '../../../../services/storage_service.dart';

/// Real implementation of MemoryRepository using Supabase
class MemoryRepositoryImpl implements MemoryRepository {
  final MemoryDataSource _memoryDataSource;
  final MemoryPhotoDataSource _photoDataSource;
  final StorageService _storageService;

  MemoryRepositoryImpl(
    this._memoryDataSource,
    this._photoDataSource,
    this._storageService,
  );

  @override
  Future<MemoryEntity?> getMemoryById(String memoryId) async {
    // In Lazzo architecture: memoryId = eventId
    return getMemoryByEventId(memoryId);
  }

  @override
  Future<MemoryEntity?> getMemoryByEventId(String eventId) async {
    try {
      // Get memory data (event)
      final memoryData = await _memoryDataSource.getMemoryByEventId(eventId);
      if (memoryData == null) return null;

      // Get photos for this memory
      final photosData = await _memoryDataSource.getMemoryPhotos(eventId);

      // Convert photos to entities with signed URLs
      final photos = <MemoryPhoto>[];
      for (final photoData in photosData) {
        final storagePath = photoData['storage_path'] as String;
        
        // Generate signed URL (with caching in StorageService)
        final signedUrl = await _storageService.getSignedUrl(storagePath);

        final isPortrait = photoData['is_portrait'] as bool? ?? false;
        final coverPhotoId = memoryData['cover_photo_id'] as String?;
        
        photos.add(MemoryPhoto(
          id: photoData['id'] as String,
          url: signedUrl,
          thumbnailUrl: null, // TODO: Generate thumbnails
          coverUrl: null,
          voteCount: 0, // TODO: Implement voting system
          capturedAt: DateTime.parse(photoData['captured_at'] as String? ?? 
                                     photoData['created_at'] as String),
          aspectRatio: isPortrait ? 0.75 : 1.33, // Portrait ~3:4, Landscape ~4:3
          uploaderId: photoData['uploader_id'] as String,
          uploaderName: photoData['uploader_id'] as String, // TODO: Join with profiles
          isCover: photoData['id'] == coverPhotoId,
        ));
      }

      // Extract location from nested JSON
      final locationsData = memoryData['locations'];
      final locationName = locationsData != null 
          ? (locationsData as Map<String, dynamic>)['display_name'] as String?
          : null;

      return MemoryEntity(
        id: memoryData['id'] as String,
        eventId: memoryData['id'] as String,
        title: memoryData['name'] as String,
        location: locationName ?? 'Unknown Location',
        eventDate: DateTime.parse(memoryData['start_datetime'] as String),
        photos: photos,
      );
    } catch (e) {
      print('❌ Error in MemoryRepositoryImpl.getMemoryByEventId: $e');
      return null;
    }
  }

  @override
  Future<String> shareMemory(String memoryId) async {
    // TODO: Implement actual share link generation
    return 'https://lazzo.app/memory/$memoryId';
  }

  @override
  Future<bool> updateCover(String memoryId, String? photoId) async {
    try {
      await _memoryDataSource.updateEventCover(
        eventId: memoryId, // memoryId = eventId
        photoId: photoId,
      );
      return true;
    } catch (e) {
      print('❌ Error updating cover: $e');
      return false;
    }
  }

  @override
  Future<bool> removePhoto(String memoryId, String photoId) async {
    try {
      // TODO: Implement photo removal (delete from group_photos + storage)
      await _photoDataSource.deletePhoto(photoId);
      return true;
    } catch (e) {
      print('❌ Error removing photo: $e');
      return false;
    }
  }
}
