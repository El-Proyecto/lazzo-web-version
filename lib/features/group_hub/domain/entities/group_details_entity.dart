/// Group details entity with full group information
class GroupDetailsEntity {
  final String id;
  final String name;
  final String? photoUrl;
  final int memberCount;
  final bool isCurrentUserAdmin;
  final bool isMuted;

  const GroupDetailsEntity({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.memberCount,
    required this.isCurrentUserAdmin,
    required this.isMuted,
  });

  GroupDetailsEntity copyWith({
    String? id,
    String? name,
    String? photoUrl,
    int? memberCount,
    bool? isCurrentUserAdmin,
    bool? isMuted,
  }) {
    return GroupDetailsEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      memberCount: memberCount ?? this.memberCount,
      isCurrentUserAdmin: isCurrentUserAdmin ?? this.isCurrentUserAdmin,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}
