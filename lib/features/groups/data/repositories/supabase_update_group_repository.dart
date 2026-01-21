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
  }) async {
    try {
      String? photoUrl;

      // Upload photo to storage if provided
      if (photoPath != null && photoPath.isNotEmpty) {
        final file = File(photoPath);
        if (!await file.exists()) {
          throw Exception('Photo file does not exist: $photoPath');
        }

        // Generate unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = photoPath.split('.').last.toLowerCase();
        final fileName = '$groupId/$timestamp.$extension';

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
        await _supabase.storage.from('group-photos').upload(
              fileName,
              file,
              fileOptions: FileOptions(
                contentType: mimeType,
                upsert: false,
              ),
            );

        // Get public URL
        photoUrl =
            _supabase.storage.from('group-photos').getPublicUrl(fileName);
      }

      // Update group in database

      final updateData = {
        'name': name,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (photoUrl != null)
          'photo_updated_at': DateTime.now().toIso8601String(),
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
          ''').single();

      // Convert to GroupEntity
      return GroupEntity(
        id: response['id'] as String,
        name: response['name'] as String,
        description: '', // Not stored in current schema
        photoUrl: response['photo_url'] as String?,
        permissions: GroupPermissions(
          membersCanInvite: response['members_can_invite'] as bool? ?? false,
          membersCanAddMembers:
              response['members_can_add_members'] as bool? ?? false,
          membersCanCreateEvents:
              response['members_can_create_events'] as bool? ?? false,
        ),
        qrCode: response['qr_code'] as String?,
        groupUrl: response['group_url'] as String?,
        createdAt: DateTime.parse(response['created_at'] as String),
      );
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }
}
