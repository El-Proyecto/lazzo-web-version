import '../../../../services/storage_service.dart';
import '../../domain/entities/group_photo_entity.dart';
import '../../domain/repositories/group_photos_repository.dart';
import '../data_sources/group_photos_data_source.dart';
import '../models/group_photo_model.dart';

/// Implementation of GroupPhotosRepository using Supabase
class GroupPhotosRepositoryImpl implements GroupPhotosRepository {
  final GroupPhotosDataSource _dataSource;
  final StorageService _storageService;

  GroupPhotosRepositoryImpl(this._dataSource, this._storageService);

  @override
  Future<List<GroupPhotoEntity>> getGroupPhotos(String groupId) async {
    try {
      
      
      List<Map<String, dynamic>> photosData;
      try {
        photosData = await _dataSource.getGroupPhotos(groupId);
      } catch (e) {
          throw Exception('Data source failed: $e');
      }
      
            
      if (photosData.isEmpty) {
          return [];
      }

      final entities = <GroupPhotoEntity>[];
      for (final json in photosData) {
        
        // Generate signed URL for the photo (from memory_groups bucket)
        String photoUrl;
        try {
          photoUrl = await _dataSource.getSignedUrl(json['storage_path'] as String);
        } catch (e) {
            // Skip this photo if we can't get a signed URL
          continue;
        }
        
        final model = GroupPhotoModel.fromJson(json);
                
        // Generate signed URL for avatar if path exists
        String? profileImageUrl;
        if (model.profileImageUrl != null && model.profileImageUrl!.isNotEmpty) {
          try {
            profileImageUrl = await _storageService.getSignedUrl(
              model.profileImageUrl!,
              bucket: 'users-profile-pic',
            );
          } catch (e) {
            profileImageUrl = null;
          }
        }
        
        entities.add(GroupPhotoEntity(
          id: model.id,
          url: photoUrl, // Use the signed URL instead of the storage path
          capturedAt: model.capturedAt,
          uploaderId: model.uploaderId,
          uploaderName: model.uploaderName,
          profileImageUrl: profileImageUrl,
          isPortrait: model.isPortrait,
        ));
      }
        return entities;
    } on Exception catch (e) {
      // Network/auth errors - rethrow
      throw Exception('Failed to load group photos: $e');
    } catch (e) {
      // Parsing errors - log and return empty
      return [];
    }
  }

  // TODO: Add upload and delete methods when needed
  // The data source already has these methods implemented:
  // - uploadPhoto() - ready to use with eventId parameter
  // - deletePhoto() - ready to use
  // They will be added to this repository when the use cases are created
}
