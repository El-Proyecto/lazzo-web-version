import '../../domain/entities/activity.dart';
import '../../domain/repositories/activity_repository.dart';

class FakeActivityRepository implements ActivityRepository {
  final List<ActivityEntity> _activities = [
    ActivityEntity(
      id: '1',
      title: 'Vote on restaurant',
      description: 'Choose between 3 restaurant options for Friday dinner',
      type: ActivityType.vote,
      status: ActivityStatus.pending,
      priority: ActivityPriority.high,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      dueDate: DateTime.now().add(const Duration(hours: 6)),
      groupId: 'group1',
      eventId: 'event1',
    ),
    ActivityEntity(
      id: '2',
      title: 'RSVP for Beach BBQ',
      description: 'Confirm your attendance for this Saturday',
      type: ActivityType.rsvp,
      status: ActivityStatus.pending,
      priority: ActivityPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      dueDate: DateTime.now().add(const Duration(days: 1)),
      groupId: 'group1',
      eventId: 'event2',
    ),
    ActivityEntity(
      id: '3',
      title: 'Pay for concert tickets',
      description: 'Transfer €45 to Maria for your concert ticket',
      type: ActivityType.payment,
      status: ActivityStatus.overdue,
      priority: ActivityPriority.urgent,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      dueDate: DateTime.now().subtract(const Duration(hours: 12)),
      groupId: 'group2',
      eventId: 'event3',
    ),
    ActivityEntity(
      id: '4',
      title: 'Bring decorations',
      description:
          'Assigned to bring balloons and streamers for birthday party',
      type: ActivityType.taskAssignment,
      status: ActivityStatus.pending,
      priority: ActivityPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      dueDate: DateTime.now().add(const Duration(days: 3)),
      groupId: 'group1',
      eventId: 'event4',
    ),
  ];

  @override
  Future<List<ActivityEntity>> getActivities({
    int limit = 20,
    int offset = 0,
    String? groupId,
    String? eventId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var activities = _activities;
    if (groupId != null) {
      activities = activities.where((a) => a.groupId == groupId).toList();
    }
    if (eventId != null) {
      activities = activities.where((a) => a.eventId == eventId).toList();
    }

    return activities.skip(offset).take(limit).toList();
  }

  @override
  Future<List<ActivityEntity>> getActivitiesByTimeLeft({
    int limit = 20,
    bool overdueFirst = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var activities = List<ActivityEntity>.from(_activities);

    activities.sort((a, b) {
      // First sort by overdue status if requested
      if (overdueFirst) {
        final aIsOverdue = a.isOverdue;
        final bIsOverdue = b.isOverdue;
        if (aIsOverdue != bIsOverdue) {
          return aIsOverdue ? -1 : 1;
        }
      }

      // Then sort by due date
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return activities.take(limit).toList();
  }

  @override
  Future<ActivityEntity?> getActivityById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _activities.where((a) => a.id == id).firstOrNull;
  }

  @override
  Future<void> markAsCompleted(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _activities.indexWhere((a) => a.id == id);
    if (index != -1) {
      _activities[index] = _activities[index].copyWith(
        status: ActivityStatus.completed,
      );
    }
  }

  @override
  Future<void> updateActivityStatus(String id, ActivityStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _activities.indexWhere((a) => a.id == id);
    if (index != -1) {
      _activities[index] = _activities[index].copyWith(status: status);
    }
  }

  @override
  Future<int> getPendingCount() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _activities.where((a) => a.status == ActivityStatus.pending).length;
  }

  @override
  Stream<List<ActivityEntity>> watchActivities() {
    return Stream.periodic(const Duration(seconds: 5), (_) => _activities);
  }
}
