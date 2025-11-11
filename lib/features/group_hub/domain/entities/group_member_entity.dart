/// Group member entity representing a member in the group details
class GroupMemberEntity {
  final String id;
  final String name;
  final String? profileImageUrl;
  final bool isAdmin;
  final bool isCurrentUser;

  const GroupMemberEntity({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.isAdmin,
    required this.isCurrentUser,
  });

  GroupMemberEntity copyWith({
    String? id,
    String? name,
    String? profileImageUrl,
    bool? isAdmin,
    bool? isCurrentUser,
  }) {
    return GroupMemberEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}
