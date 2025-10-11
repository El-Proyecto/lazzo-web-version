import '../entities/poll.dart';
import '../repositories/poll_repository.dart';

/// Use case to get event polls
class GetEventPolls {
  final PollRepository repository;

  const GetEventPolls(this.repository);

  Future<List<Poll>> call(String eventId) async {
    return await repository.getEventPolls(eventId);
  }
}
