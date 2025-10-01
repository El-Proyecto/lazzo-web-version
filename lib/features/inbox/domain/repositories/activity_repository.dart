import '../entities/activity.dart';

abstract class ActivityRepository {
  Future<List<ActivityEntity>> getActivities({
    int limit = 20,
    int offset = 0,
    String? groupId,
    String? eventId,
  });

  Future<List<ActivityEntity>> getActivitiesByTimeLeft({
    int limit = 20,
    bool overdueFirst = true,
  });

  Future<ActivityEntity?> getActivityById(String id);

  Future<void> markAsCompleted(String id);

  Future<void> updateActivityStatus(String id, ActivityStatus status);

  Future<int> getPendingCount();

  Stream<List<ActivityEntity>> watchActivities();
}
