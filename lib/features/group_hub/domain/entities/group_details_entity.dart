import '../../../groups/domain/entities/group_permissions.dart';

/// Group details entity with full group information
class GroupDetailsEntity {
  final String id;
  final String name;
  final String? photoUrl;
  final int memberCount;
  final bool isCurrentUserAdmin;
  final bool isMuted;
  final GroupPermissions permissions;

  const GroupDetailsEntity({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.memberCount,
    required this.isCurrentUserAdmin,
    required this.isMuted,
    required this.permissions,
  });

  GroupDetailsEntity copyWith({
    String? id,
    String? name,
    String? photoUrl,
    int? memberCount,
    bool? isCurrentUserAdmin,
    bool? isMuted,
    GroupPermissions? permissions,
  }) {
    return GroupDetailsEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      memberCount: memberCount ?? this.memberCount,
      isCurrentUserAdmin: isCurrentUserAdmin ?? this.isCurrentUserAdmin,
      isMuted: isMuted ?? this.isMuted,
      permissions: permissions ?? this.permissions,
    );
  }
}
