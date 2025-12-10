import '../../domain/entities/invite_group_entity.dart';
import '../../domain/entities/other_profile_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/other_profile_repository.dart';
import '../../../group_hub/domain/entities/group_event_entity.dart';
import '../data_sources/other_profile_data_source.dart';
import '../models/other_profile_model.dart';
import '../../../../services/storage_service.dart';

/// Implementation of OtherProfileRepository using Supabase
/// Bridges data source → domain entities with signed URL generation
class OtherProfileRepositoryImpl implements OtherProfileRepository {
  final OtherProfileDataSource _dataSource;
  final StorageService _storageService;
  final String _currentUserId;

  OtherProfileRepositoryImpl({
    required OtherProfileDataSource dataSource,
    required StorageService storageService,
    required String currentUserId,
  })  : _dataSource = dataSource,
        _storageService = storageService,
        _currentUserId = currentUserId;

  @override
  Future<OtherProfileEntity> getOtherUserProfile(String userId) async {
    print('[OtherProfileRepo] Fetching profile for user: $userId');
    
    try {
      // Fetch basic profile data
      final profileData = await _dataSource.getOtherUserProfile(userId);
      print('[OtherProfileRepo] Profile data received: ${profileData['name']}');
      final profileModel = OtherProfileModel.fromMap(profileData);

      // Generate signed URL for avatar if exists
      // Note: NULL avatar_url is expected when user hasn't uploaded profile picture
      String? signedAvatarUrl;
      if (profileModel.avatarUrl != null && profileModel.avatarUrl!.isNotEmpty) {
        print('[OtherProfileRepo] Generating signed URL for avatar');
        try {
          signedAvatarUrl = await _storageService.getSignedUrl(
            profileModel.avatarUrl!,
            bucket: 'users-profile-pic',
            expiresInSeconds: 3600, // 1 hour
          );
          print('[OtherProfileRepo] ✅ Avatar signed URL generated');
        } catch (e) {
          print('[OtherProfileRepo] ❌ Avatar signed URL error: $e');
          signedAvatarUrl = null;
        }
      }

      // Fetch shared memories data
      print('[OtherProfileRepo] Fetching shared memories...');
      final sharedMemoriesData = await _dataSource.getSharedMemories(
        currentUserId: _currentUserId,
        targetUserId: userId,
      );
      print('[OtherProfileRepo] Data source returned ${sharedMemoriesData.length} memories');

      // Convert shared memories to entities with signed URLs
      final memoriesList = <MemoryEntity>[];
      
      for (final memoryData in sharedMemoriesData) {
        String? signedCoverUrl;
        final coverPath = memoryData['cover_storage_path'] as String?;
        
        if (coverPath != null && coverPath.isNotEmpty) {
          print('[OtherProfileRepo] Generating signed URL for path: $coverPath');
          try {
            // Note: photos are stored in 'memory_groups' bucket, not 'group_photos'
            // The table name is group_photos but the storage bucket is memory_groups
            signedCoverUrl = await _storageService.getSignedUrl(
              coverPath,
              bucket: 'memory_groups',
              expiresInSeconds: 3600,
            );
            print('[OtherProfileRepo] ✅ Signed URL generated successfully');
          } catch (e) {
            print('[OtherProfileRepo] ❌ Signed URL error for ${memoryData['title']}: $e');
            signedCoverUrl = null;
          }
        } else {
          print('[OtherProfileRepo] ⚠️ No storage path for ${memoryData['title']}');
        }

        memoriesList.add(MemoryEntity(
          id: memoryData['id'] as String,
          title: memoryData['title'] as String? ?? 'Untitled',
          coverImageUrl: signedCoverUrl,
          date: memoryData['date'] != null 
              ? DateTime.parse(memoryData['date'] as String)
              : DateTime.now(),
          location: memoryData['location'] as String?,
        ));
      }
      
      print('[OtherProfileRepo] Final memories with signed URLs: ${memoriesList.length}');

      // Fetch upcoming events data
      final upcomingEventsData = await _dataSource.getSharedUpcomingEvents(
        currentUserId: _currentUserId,
        targetUserId: userId,
      );

      // Convert upcoming events to entities (simplified - just basic info)
      final upcomingList = upcomingEventsData.map((eventData) {
        return GroupEventEntity(
          id: eventData['id'] as String,
          name: eventData['name'] as String? ?? 'Untitled Event',
          emoji: eventData['emoji'] as String? ?? '📅',
          date: eventData['start_datetime'] != null
              ? DateTime.parse(eventData['start_datetime'] as String)
              : null,
          endDate: eventData['end_datetime'] != null
              ? DateTime.parse(eventData['end_datetime'] as String)
              : null,
          location: (eventData['locations'] as Map?)?['display_name'] as String?,
          status: _parseEventStatus(eventData['status'] as String?),
          goingCount: 0,
          participantCount: 0,
          attendeeAvatars: const [],
          attendeeNames: const [],
        );
      }).toList();

      // Convert to entity with lists
      print('[OtherProfileRepo] Creating entity with:');
      print('  - Avatar URL: ${signedAvatarUrl != null ? "✅ Present" : "❌ Missing"}');
      print('  - Memories: ${memoriesList.length}');
      print('  - Upcoming events: ${upcomingList.length}');
      
      return profileModel.toEntity(
        signedAvatarUrl: signedAvatarUrl,
        memoriesTogether: memoriesList,
        upcomingTogether: upcomingList,
      );
    } catch (e) {
      // Return minimal entity on error
      return const OtherProfileEntity(
        id: '',
        name: 'Unknown User',
        memoriesTogether: [],
        upcomingTogether: [],
      );
    }
  }

  /// Parse event status string to enum
  GroupEventStatus _parseEventStatus(String? status) {
    switch (status) {
      case 'pending':
      case 'planning':
        return GroupEventStatus.pending;
      case 'confirmed':
        return GroupEventStatus.confirmed;
      case 'living':
        return GroupEventStatus.living;
      case 'recap':
        return GroupEventStatus.recap;
      default:
        return GroupEventStatus.pending;
    }
  }

  @override
  Future<List<InviteGroupEntity>> getInvitableGroups(String userId) async {
    try {
      final groupsData = await _dataSource.getInvitableGroups(
        currentUserId: _currentUserId,
        targetUserId: userId,
      );

      // Convert to entities with signed URLs for group photos
      final entities = <InviteGroupEntity>[];
      for (final groupData in groupsData) {
        String? signedPhotoUrl;
        final photoUrl = groupData['photo_url'] as String?;
        
        if (photoUrl != null && photoUrl.isNotEmpty) {
          print('[InvitableGroups] Generating signed URL for group photo: $photoUrl');
          try {
            // Note: group photos are stored in 'group-photos' bucket (with hyphen)
            signedPhotoUrl = await _storageService.getSignedUrl(
              photoUrl,
              bucket: 'group-photos',
              expiresInSeconds: 3600,
            );
            print('[InvitableGroups] ✅ Group photo signed URL generated');
          } catch (e) {
            print('[InvitableGroups] ❌ Group photo signed URL error: $e');
            signedPhotoUrl = null;
          }
        }

        entities.add(InviteGroupEntity(
          id: groupData['id'] as String,
          name: groupData['name'] as String? ?? 'Unnamed Group',
          groupPhotoUrl: signedPhotoUrl,
          memberCount: groupData['member_count'] as int? ?? 0,
        ));
      }

      return entities;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> inviteToGroup({
    required String userId,
    required String groupId,
  }) async {
    try {
      await _dataSource.inviteToGroup(
        userId: userId,
        groupId: groupId,
        invitedBy: _currentUserId,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
