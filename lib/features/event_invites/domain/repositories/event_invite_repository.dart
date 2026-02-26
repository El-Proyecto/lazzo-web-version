import '../entities/event_invite_link_entity.dart';

abstract class EventInviteRepository {
  /// Get or create an invite link for an event.
  /// Returns token + expiry. Reuses existing valid token if available.
  Future<EventInviteLinkEntity> createInviteLink({
    required String eventId,
    int expiresInHours = 48,
    String? shareChannel,
  });
}
