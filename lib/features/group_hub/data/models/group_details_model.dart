import '../../../groups/domain/entities/group_permissions.dart';
import '../../domain/entities/group_details_entity.dart';

/// Model/DTO for converting Supabase JSON to GroupDetailsEntity
class GroupDetailsModel {
  final String id;
  final String name;
  final String? photoUrl;
  final int memberCount;
  final bool isCurrentUserAdmin;
  final bool isMuted;
  final GroupPermissions permissions;

  const GroupDetailsModel({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.memberCount,
    required this.isCurrentUserAdmin,
    required this.isMuted,
    required this.permissions,
  });

  /// Parse from Supabase JSON response
  factory GroupDetailsModel.fromJson(
    Map<String, dynamic> json, {
    required int memberCount,
    required bool isCurrentUserAdmin,
    required bool isMuted,
  }) {
    return GroupDetailsModel(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String?,
      memberCount: memberCount,
      isCurrentUserAdmin: isCurrentUserAdmin,
      isMuted: isMuted,
      permissions: GroupPermissions(
        membersCanInvite: json['members_can_invite'] as bool? ?? false,
        membersCanAddMembers: json['members_can_add_members'] as bool? ?? false,
        membersCanCreateEvents: json['members_can_create_events'] as bool? ?? false,
      ),
    );
  }

  /// Convert to domain entity
  GroupDetailsEntity toEntity() {
    return GroupDetailsEntity(
      id: id,
      name: name,
      photoUrl: photoUrl,
      memberCount: memberCount,
      isCurrentUserAdmin: isCurrentUserAdmin,
      isMuted: isMuted,
      permissions: permissions,
    );
  }
}
