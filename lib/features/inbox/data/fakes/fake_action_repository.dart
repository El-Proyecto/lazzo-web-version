import '../../domain/entities/action.dart';
import '../../domain/repositories/action_repository.dart';

/// Fake action repository providing sample host actions for development.
class FakeActionRepository implements ActionRepository {
  final List<ActionEntity> _actions = [
    // Host needs to remind maybe voters before Friday Dinner
    ActionEntity(
      id: 'action-1',
      title: 'Remind maybe voters',
      subtitle: '3 guests haven\'t responded yet',
      type: ActionType.remindMaybeVoters,
      status: ActionStatus.pending,
      priority: ActionPriority.high,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      dueDate: DateTime.now().add(const Duration(days: 2)),
      eventId: 'event-1',
      eventName: 'Friday Dinner',
      eventEmoji: '🍽️',
      contextInfo: '3 guests haven\'t responded',
    ),

    // Confirm event — only shown 24h before
    ActionEntity(
      id: 'action-2',
      title: 'Confirm event',
      subtitle: 'Event starts in less than 24h',
      type: ActionType.confirmEvent,
      status: ActionStatus.pending,
      priority: ActionPriority.urgent,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      dueDate: DateTime.now().add(const Duration(hours: 18)),
      eventId: 'event-2',
      eventName: 'Beach BBQ',
      eventEmoji: '🏖️',
      contextInfo: 'Starts tomorrow — confirm now',
    ),

    // Host has an expired event that needs rescheduling
    ActionEntity(
      id: 'action-3',
      title: 'Reschedule event',
      subtitle: 'Event has expired — set new dates',
      type: ActionType.rescheduleExpiredEvent,
      status: ActionStatus.pending,
      priority: ActionPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      eventId: 'event-3',
      eventName: 'Birthday Party',
      eventEmoji: '🎂',
      contextInfo: 'Event has expired — set new dates',
    ),

    // Host should review guests who are still "maybe"
    ActionEntity(
      id: 'action-4',
      title: 'Review guest list',
      subtitle: '2 guests are still maybe',
      type: ActionType.reviewGuests,
      status: ActionStatus.pending,
      priority: ActionPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      dueDate: DateTime.now().add(const Duration(days: 3)),
      eventId: 'event-4',
      eventName: 'Concert Night',
      eventEmoji: '🎵',
      contextInfo: '2 guests are still maybe',
    ),

    // Host should upload photos during living phase
    ActionEntity(
      id: 'action-5',
      title: 'Add photos',
      subtitle: 'You haven\'t added any photos yet',
      type: ActionType.addPhotos,
      status: ActionStatus.pending,
      priority: ActionPriority.high,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      dueDate: DateTime.now().add(const Duration(hours: 4)),
      eventId: 'event-5',
      eventName: 'Weekend Trip',
      eventEmoji: '⛺',
      contextInfo: 'You haven\'t added any photos yet',
    ),
  ];

  final Set<String> _dismissedIds = {};

  @override
  Future<List<ActionEntity>> getActions() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _actions
        .where((a) =>
            a.status == ActionStatus.pending && !_dismissedIds.contains(a.id))
        .toList()
      ..sort((a, b) {
        // Urgent first, then by due date
        final priorityOrder = b.priority.index.compareTo(a.priority.index);
        if (priorityOrder != 0) return priorityOrder;
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
  }

  @override
  Future<void> dismissAction(String actionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _dismissedIds.add(actionId);
  }

  @override
  Future<int> getPendingCount() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _actions
        .where((a) =>
            a.status == ActionStatus.pending && !_dismissedIds.contains(a.id))
        .length;
  }
}
