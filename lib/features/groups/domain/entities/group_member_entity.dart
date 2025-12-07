class GroupMemberEntity {
  final String id;
  final String name;
  final String? avatarUrl;
  final String role; // 'admin' or 'member'

  const GroupMemberEntity({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.role,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMemberEntity &&
        other.id == id &&
        other.name == name &&
        other.avatarUrl == avatarUrl &&
        other.role == role;
  }

  @override
  int get hashCode => Object.hash(id, name, avatarUrl, role);
}