import '../../domain/entities/group_photo_entity.dart';
import '../../domain/repositories/group_photos_repository.dart';
import '../data_sources/group_photos_data_source.dart';
import '../models/group_photo_model.dart';

/// Implementation of GroupPhotosRepository using Supabase
class GroupPhotosRepositoryImpl implements GroupPhotosRepository {
  final GroupPhotosDataSource _dataSource;

  GroupPhotosRepositoryImpl(this._dataSource);

  @override
  Future<List<GroupPhotoEntity>> getMemoryPhotos(String memoryId) async {
    try {
      print('\n📸 [GROUP PHOTOS REPO] Getting photos for memory: $memoryId');
      final photosData = await _dataSource.getEventPhotos(memoryId);
      
      print('📸 [GROUP PHOTOS REPO] Received ${photosData.length} photos from data source');
      
      if (photosData.isEmpty) {
        return [];
      }

      final entities = photosData
          .map((json) {
            print('   - Photo: ${json['id']}');
            print('     uploader_id: ${json['uploader_id']}');
            print('     profiles: ${json['profiles']}');
            
            final model = GroupPhotoModel.fromJson(json);
            print('     → uploaderName after parsing: "${model.uploaderName}"');
            
            return model.toEntity();
          })
          .toList();
      
      print('✅ [GROUP PHOTOS REPO] Returning ${entities.length} entities');
      return entities;
    } on Exception catch (e) {
      // Network/auth errors - rethrow
      throw Exception('Failed to load event photos: $e');
    } catch (e) {
      // Parsing errors - log and return empty
      print('❌ Error parsing photo data: $e');
      return [];
    }
  }

  // TODO: Add upload and delete methods when needed
  // The data source already has these methods implemented:
  // - uploadPhoto() - ready to use with eventId parameter
  // - deletePhoto() - ready to use
  // They will be added to this repository when the use cases are created
}
