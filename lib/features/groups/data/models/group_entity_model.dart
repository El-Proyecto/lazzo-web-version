import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_permissions.dart';

/// DTO model for GroupEntity serialization/deserialization
class GroupEntityModel {
  static GroupEntity fromJson(Map<String, dynamic> json) {
    return GroupEntity(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      qrCode: json['qr_code'] as String?,
      groupUrl: json['group_url'] as String?,
      permissions: GroupPermissions(
        membersCanInvite: json['members_can_invite'] as bool? ?? false,
        membersCanAddMembers: json['members_can_add_members'] as bool? ?? false,
        membersCanCreateEvents: json['members_can_create_events'] as bool? ?? false,
      ),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  static Map<String, dynamic> toJson(GroupEntity entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'description': entity.description,
      'photo_url': entity.photoUrl,
      'qr_code': entity.qrCode,
      'group_url': entity.groupUrl,
      'members_can_invite': entity.permissions.membersCanInvite,
      'members_can_add_members': entity.permissions.membersCanAddMembers,
      'members_can_create_events': entity.permissions.membersCanCreateEvents,
      'created_at': entity.createdAt?.toIso8601String(),
    };
  }

  /// Converte GroupEntity para formato esperado pelo data source
  static Map<String, dynamic> toDataSourceFormat(GroupEntity entity, String userId) {
    return {
      'name': entity.name,
      'description': entity.description,
      'photo_url': entity.photoUrl,
      'qr_code': entity.qrCode,
      'group_url': entity.groupUrl,
      'created_by': userId,
      'members_can_invite': entity.permissions.membersCanInvite,
      'members_can_add_members': entity.permissions.membersCanAddMembers,
      'members_can_create_events': entity.permissions.membersCanCreateEvents,
    };
  }
}