/// Entity representing an event invite link token + expiry.
class EventInviteLinkEntity {
  final String token;
  final DateTime expiresAt;

  const EventInviteLinkEntity({
    required this.token,
    required this.expiresAt,
  });
}
