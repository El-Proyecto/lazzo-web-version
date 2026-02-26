import '../entities/event_invite_link_entity.dart';
import '../repositories/event_invite_repository.dart';

class CreateEventInviteLink {
  final EventInviteRepository repository;

  CreateEventInviteLink(this.repository);

  Future<EventInviteLinkEntity> call({
    required String eventId,
    int expiresInHours = 48,
    String? shareChannel,
  }) {
    return repository.createInviteLink(
      eventId: eventId,
      expiresInHours: expiresInHours,
      shareChannel: shareChannel,
    );
  }
}
