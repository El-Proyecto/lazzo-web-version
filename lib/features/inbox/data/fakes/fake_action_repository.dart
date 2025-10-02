import '../../domain/entities/action.dart';
import '../../domain/repositories/action_repository.dart';

class FakeActionRepository implements ActionRepository {
  final List<ActionEntity> _actions = [
    // action.vote.date - Vote a date · closes {weekday}
    ActionEntity(
      id: '1',
      title: 'Vote a date',
      description: 'Vote for the best date for our dinner',
      type: ActionType.voteDate,
      status: ActionStatus.pending,
      priority: ActionPriority.high,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      dueDate: DateTime.now().add(const Duration(days: 2)),
      groupId: 'group1',
      eventId: 'event1',
      eventEmoji: '🍽️',
    ),

    // action.vote.place - Vote a place · closes {weekday}
    ActionEntity(
      id: '2',
      title: 'Vote a place',
      description: 'Vote for the place where we\'ll watch the game',
      type: ActionType.votePlace,
      status: ActionStatus.pending,
      priority: ActionPriority.high,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      dueDate: DateTime.now().add(const Duration(days: 3)),
      groupId: 'group1',
      eventId: 'event2',
      eventEmoji: '⚽',
    ),

    // action.confirm.attendance - Confirm attendance · {days}d left
    ActionEntity(
      id: '3',
      title: 'Confirm attendance',
      description: 'Confirm if you\'re going to the beach day',
      type: ActionType.confirmAttendance,
      status: ActionStatus.pending,
      priority: ActionPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      dueDate: DateTime.now().add(const Duration(days: 3)),
      groupId: 'group2',
      eventId: 'event3',
      eventEmoji: '🏖️',
    ),

    // action.complete.details - Complete event details (date/location)
    ActionEntity(
      id: '4',
      title: 'Complete details',
      description: 'Add missing details about the birthday party',
      type: ActionType.completeDetails,
      status: ActionStatus.pending,
      priority: ActionPriority.high,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      dueDate: DateTime.now().add(const Duration(days: 1)),
      groupId: 'group2',
      eventId: 'event4',
      eventEmoji: '�',
    ),

    // action.add.photos - Add photos · {hours}h left
    ActionEntity(
      id: '5',
      title: 'Add photos',
      description: 'Add photos from last weekend\'s trip',
      type: ActionType.addPhotos,
      status: ActionStatus.pending,
      priority: ActionPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      dueDate: DateTime.now().add(const Duration(hours: 4)),
      groupId: 'group3',
      eventId: 'event5',
      eventEmoji: '📸',
    ),

    // Some completed actions for variety
    ActionEntity(
      id: '6',
      title: 'Vote a date',
      description: 'Vote for the best date for movie night',
      type: ActionType.voteDate,
      status: ActionStatus.completed,
      priority: ActionPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      dueDate: DateTime.now().subtract(const Duration(hours: 6)),
      groupId: 'group1',
      eventId: 'event6',
      eventEmoji: '🎬',
    ),

    // action.vote.place - Vote a place · closes {weekday}
    ActionEntity(
      id: '2',
      title: 'Vote a place',
      description: 'Vote a place · closes Friday',
      type: ActionType.votePlace,
      status: ActionStatus.pending,
      priority: ActionPriority.high,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      dueDate: DateTime.now().add(const Duration(days: 3)),
      groupId: 'group1',
      eventId: 'event2',
      eventEmoji: '�️',
      weekday: 'Friday',
    ),

    // action.confirm.attendance - Confirm attendance · {days}d left
    ActionEntity(
      id: '3',
      title: 'Confirm attendance',
      description: 'Confirm attendance · 3d left',
      type: ActionType.confirmAttendance,
      status: ActionStatus.pending,
      priority: ActionPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      dueDate: DateTime.now().add(const Duration(days: 3)),
      groupId: 'group2',
      eventId: 'event3',
      eventEmoji: '�',
      days: '3',
    ),

    // action.complete.details - Complete event details (date/location)
    ActionEntity(
      id: '4',
      title: 'Complete event details',
      description: 'Complete event details (date/location)',
      type: ActionType.completeDetails,
      status: ActionStatus.pending,
      priority: ActionPriority.high,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      dueDate: DateTime.now().add(const Duration(days: 1)),
      groupId: 'group2',
      eventId: 'event4',
      eventEmoji: '⚽',
    ),

    // action.add.photos - Add photos · {hours}h left
    ActionEntity(
      id: '5',
      title: 'Add photos',
      description: 'Add photos · 4h left',
      type: ActionType.addPhotos,
      status: ActionStatus.pending,
      priority: ActionPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      dueDate: DateTime.now().add(const Duration(hours: 4)),
      groupId: 'group3',
      eventId: 'event5',
      eventEmoji: '🎂',
      hours: '4',
    ),

    // Some completed actions for variety
    ActionEntity(
      id: '6',
      title: 'Vote date - Movie Night',
      description: 'Vote for the best date for movie night',
      type: ActionType.voteDate,
      status: ActionStatus.completed,
      priority: ActionPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      dueDate: DateTime.now().subtract(const Duration(hours: 6)),
      groupId: 'group1',
      eventId: 'event6',
      eventEmoji: '🎬',
      weekday: 'Monday',
    ),
  ];

  @override
  Future<List<ActionEntity>> getActions({
    int limit = 20,
    int offset = 0,
    String? groupId,
    String? eventId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var actions = _actions;
    if (groupId != null) {
      actions = actions.where((a) => a.groupId == groupId).toList();
    }
    if (eventId != null) {
      actions = actions.where((a) => a.eventId == eventId).toList();
    }

    return actions.skip(offset).take(limit).toList();
  }

  @override
  Future<List<ActionEntity>> getActionsByTimeLeft({
    int limit = 20,
    bool overdueFirst = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var actions = List<ActionEntity>.from(_actions);

    actions.sort((a, b) {
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

    return actions.take(limit).toList();
  }

  @override
  Future<ActionEntity?> getActionById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _actions.where((a) => a.id == id).firstOrNull;
  }

  @override
  Future<void> markAsCompleted(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _actions.indexWhere((a) => a.id == id);
    if (index != -1) {
      _actions[index] = _actions[index].copyWith(
        status: ActionStatus.completed,
      );
    }
  }

  @override
  Future<void> updateActionStatus(String id, ActionStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _actions.indexWhere((a) => a.id == id);
    if (index != -1) {
      _actions[index] = _actions[index].copyWith(status: status);
    }
  }

  @override
  Future<int> getPendingCount() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _actions.where((a) => a.status == ActionStatus.pending).length;
  }

  @override
  Stream<List<ActionEntity>> watchActions() {
    return Stream.periodic(const Duration(seconds: 5), (_) => _actions);
  }
}
