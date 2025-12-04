import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_permissions.dart';
import '../../domain/repositories/update_group_repository.dart';

/// Supabase implementation of UpdateGroupRepository
class SupabaseUpdateGroupRepository implements UpdateGroupRepository {
  final SupabaseClient _supabase;

  SupabaseUpdateGroupRepository(this._supabase);

  @override
  Future<GroupEntity> updateGroup({
    required String groupId,
    required String name,
    String? description,
    String? photoPath,
    required bool canEditSettings,
    required bool canAddMembers,
    required bool canSendMessages,
  }) async {
    try {
      print('\n📝 [UPDATE GROUP REPO] Starting update for group: $groupId');
      print('   Name: $name');
      print('   Photo path: ${photoPath ?? "no change"}');

      String? photoUrl;
      
      // Upload photo to storage if provided
      if (photoPath != null && photoPath.isNotEmpty) {
        print('📤 [UPDATE GROUP REPO] Uploading photo to storage...');
        
        final file = File(photoPath);
        if (!await file.exists()) {
          throw Exception('Photo file does not exist: $photoPath');
        }

        // Generate unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = photoPath.split('.').last.toLowerCase();
        final fileName = '$groupId/$timestamp.$extension';

        print('   Storage path: $fileName');
        
        // Determine MIME type
        String mimeType;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'heic':
            mimeType = 'image/heic';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
          default:
            mimeType = 'image/jpeg';
        }

        // Upload to storage
        final uploadPath = await _supabase.storage
            .from('group-photos')
            .upload(
              fileName,
              file,
              fileOptions: FileOptions(
                contentType: mimeType,
                upsert: false,
              ),
            );

        print('✅ [UPDATE GROUP REPO] Photo uploaded: $uploadPath');

        // Get public URL
        photoUrl = _supabase.storage
            .from('group-photos')
            .getPublicUrl(fileName);

        print('   Public URL: $photoUrl');
      }

      // Update group in database
      print('💾 [UPDATE GROUP REPO] Updating database...');
      
      final updateData = {
        'name': name,
        'members_can_invite': canEditSettings,
        'members_can_add_members': canAddMembers,
        'members_can_create_events': canSendMessages,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (photoUrl != null) 'photo_updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('groups')
          .update(updateData)
          .eq('id', groupId)
          .select('''
            id,
            name,
            photo_url,
            members_can_invite,
            members_can_add_members,
            members_can_create_events,
            qr_code,
            group_url,
            created_at
          ''')
          .single();

      print('✅ [UPDATE GROUP REPO] Database updated successfully');

      // Convert to GroupEntity
      return GroupEntity(
        id: response['id'] as String,
        name: response['name'] as String,
        description: '', // Not stored in current schema
        photoUrl: response['photo_url'] as String?,
        permissions: GroupPermissions(
          membersCanInvite: response['members_can_invite'] as bool? ?? false,
          membersCanAddMembers: response['members_can_add_members'] as bool? ?? false,
          membersCanCreateEvents: response['members_can_create_events'] as bool? ?? false,
        ),
        qrCode: response['qr_code'] as String?,
        groupUrl: response['group_url'] as String?,
        createdAt: DateTime.parse(response['created_at'] as String),
      );
    } catch (e, stackTrace) {
      print('❌ [UPDATE GROUP REPO] Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to update group: $e');
    }
  }
}
