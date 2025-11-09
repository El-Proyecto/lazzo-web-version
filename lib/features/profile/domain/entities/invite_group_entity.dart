/// Entity representing a group that the current user can invite others to
class InviteGroupEntity {
  final String id;
  final String name;
  final String? groupPhotoUrl;
  final int memberCount;

  const InviteGroupEntity({
    required this.id,
    required this.name,
    this.groupPhotoUrl,
    required this.memberCount,
  });
}
