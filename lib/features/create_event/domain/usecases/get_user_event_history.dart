import '../entities/event_history.dart';
import '../repositories/event_repository.dart';

/// Use case: Get user's event history for template reuse
/// Returns recent events ordered by date (most recent first)
class GetUserEventHistory {
  final EventRepository repository;

  const GetUserEventHistory(this.repository);

  Future<List<EventHistory>> call({
    required String userId,
    int limit = 10,
  }) async {
    return repository.getUserEventHistory(
      userId: userId,
      limit: limit,
    );
  }
}
