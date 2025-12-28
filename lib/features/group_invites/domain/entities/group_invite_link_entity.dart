class GroupInviteLinkEntity {
  final String token;
  final DateTime expiresAt;

  const GroupInviteLinkEntity({
    required this.token,
    required this.expiresAt,
  });
}
