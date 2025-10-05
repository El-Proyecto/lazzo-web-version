import '../entities/rsvp.dart';
import '../repositories/rsvp_repository.dart';

/// Use case to submit RSVP
class SubmitRsvp {
  final RsvpRepository repository;

  const SubmitRsvp(this.repository);

  Future<Rsvp> call(String eventId, String userId, RsvpStatus status) async {
    return await repository.submitRsvp(eventId, userId, status);
  }
}
