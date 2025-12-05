import '../../domain/entities/group_photo_entity.dart';
import '../../domain/repositories/group_photos_repository.dart';

/// Fake repository for group photos (P1)
/// Returns mock photo data for development
class FakeGroupPhotosRepository implements GroupPhotosRepository {
  @override
  Future<List<GroupPhotoEntity>> getGroupPhotos(String groupId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return fake photos
    return [
      GroupPhotoEntity(
        id: 'photo-1',
        url: 'https://picsum.photos/400/500',
        capturedAt: DateTime.now().subtract(const Duration(hours: 2)),
        uploaderId: 'user-1',
        uploaderName: 'Marco Silva',
        isPortrait: true,
      ),
      GroupPhotoEntity(
        id: 'photo-2',
        url: 'https://picsum.photos/600/400',
        capturedAt:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        uploaderId: 'user-2',
        uploaderName: 'Ana Costa',
        isPortrait: false,
      ),
      GroupPhotoEntity(
        id: 'photo-3',
        url: 'https://picsum.photos/400/500',
        capturedAt: DateTime.now().subtract(const Duration(hours: 1)),
        uploaderId: 'user-3',
        uploaderName: 'João Santos',
        isPortrait: true,
      ),
      GroupPhotoEntity(
        id: 'photo-4',
        url: 'https://picsum.photos/500/500',
        capturedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        uploaderId: 'user-1',
        uploaderName: 'Marco Silva',
        isPortrait: true,
      ),
      GroupPhotoEntity(
        id: 'photo-5',
        url: 'https://picsum.photos/600/400',
        capturedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        uploaderId: 'user-4',
        uploaderName: 'Maria Oliveira',
        isPortrait: false,
      ),
      GroupPhotoEntity(
        id: 'photo-6',
        url: 'https://picsum.photos/400/500',
        capturedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        uploaderId: 'user-2',
        uploaderName: 'Ana Costa',
        isPortrait: true,
      ),
      GroupPhotoEntity(
        id: 'photo-7',
        url: 'https://picsum.photos/500/400',
        capturedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        uploaderId: 'user-3',
        uploaderName: 'João Santos',
        isPortrait: false,
      ),
      GroupPhotoEntity(
        id: 'photo-8',
        url: 'https://picsum.photos/400/500',
        capturedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        uploaderId: 'user-1',
        uploaderName: 'Marco Silva',
        isPortrait: true,
      ),
      GroupPhotoEntity(
        id: 'photo-9',
        url: 'https://picsum.photos/600/400',
        capturedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        uploaderId: 'user-4',
        uploaderName: 'Maria Oliveira',
        isPortrait: false,
      ),
      GroupPhotoEntity(
        id: 'photo-10',
        url: 'https://picsum.photos/400/500',
        capturedAt: DateTime.now(),
        uploaderId: 'user-2',
        uploaderName: 'Ana Costa',
        isPortrait: true,
      ),
    ];
  }
}
