import '../../domain/entities/group_member_entity.dart';

class GroupMemberDto {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String role;

  const GroupMemberDto({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.role,
  });

  factory GroupMemberDto.fromJson(Map<String, dynamic> json) {
    final userData = json['users'] as Map<String, dynamic>?;
    
    return GroupMemberDto(
      userId: json['user_id'] as String,
      displayName: userData?['display_name'] as String? ?? 'Unknown',
      avatarUrl: userData?['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
    );
  }

  GroupMemberEntity toEntity() {
    return GroupMemberEntity(
      id: userId,
      name: displayName,
      avatarUrl: avatarUrl,
      role: role,
    );
  }
}