import '../entities/activity.dart';
import '../repositories/activity_repository.dart';

class GetUserActivities {
  final ActivityRepository repository;

  const GetUserActivities(this.repository);

  Future<List<ActivityEntity>> call({
    int limit = 20,
    int offset = 0,
    String? groupId,
    String? eventId,
  }) {
    return repository.getActivities(
      limit: limit,
      offset: offset,
      groupId: groupId,
      eventId: eventId,
    );
  }
}

class GetActivitiesByTimeLeft {
  final ActivityRepository repository;

  const GetActivitiesByTimeLeft(this.repository);

  Future<List<ActivityEntity>> call({
    int limit = 20,
    bool overdueFirst = true,
  }) {
    return repository.getActivitiesByTimeLeft(
      limit: limit,
      overdueFirst: overdueFirst,
    );
  }
}

class CompleteActivity {
  final ActivityRepository repository;

  const CompleteActivity(this.repository);

  Future<void> call(String id) {
    return repository.markAsCompleted(id);
  }
}
