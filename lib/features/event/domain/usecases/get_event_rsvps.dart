import '../entities/rsvp.dart';
import '../repositories/rsvp_repository.dart';

/// Use case to get event RSVPs
class GetEventRsvps {
  final RsvpRepository repository;

  const GetEventRsvps(this.repository);

  Future<List<Rsvp>> call(String eventId) async {
    return await repository.getEventRsvps(eventId);
  }
}
