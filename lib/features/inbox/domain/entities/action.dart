// Based on notifications_catalog.md ACTIONS section
enum ActionType {
  // Legacy types for compatibility
  vote,
  rsvp,
  payment,
  taskAssignment,
  eventPreparation,

  // New specific action types from catalog
  voteDate, // action.vote.date - Vote a date · closes {weekday}
  votePlace, // action.vote.place - Vote a place · closes {weekday}
  confirmAttendance, // action.confirm.attendance - Confirm attendance · {days}d left
  completeDetails, // action.complete.details - Complete event details (date/location)
  addPhotos, // action.add.photos - Add photos · {hours}h left
}

enum ActionStatus { pending, completed, overdue, cancelled }

enum ActionPriority { low, medium, high, urgent }

class ActionEntity {
  final String id;
  final String title;
  final String description;
  final ActionType type;
  final ActionStatus status;
  final ActionPriority priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? groupId;
  final String? eventId;
  final String? assigneeId;
  final String? eventEmoji;
  final String? weekday; // For vote actions - "closes {weekday}"
  final String? days; // For attendance confirmation - "{days}d left"
  final String? hours; // For photo uploads - "{hours}h left"
  final Map<String, dynamic>? metadata;

  const ActionEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    this.groupId,
    this.eventId,
    this.assigneeId,
    this.eventEmoji,
    this.weekday,
    this.days,
    this.hours,
    this.metadata,
  });

  Duration? get timeLeft {
    if (dueDate == null) return null;
    final now = DateTime.now();
    return dueDate!.isAfter(now) ? dueDate!.difference(now) : null;
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status == ActionStatus.pending;
  }

  ActionEntity copyWith({
    String? id,
    String? title,
    String? description,
    ActionType? type,
    ActionStatus? status,
    ActionPriority? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    String? groupId,
    String? eventId,
    String? assigneeId,
    String? eventEmoji,
    String? weekday,
    String? days,
    String? hours,
    Map<String, dynamic>? metadata,
  }) {
    return ActionEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      groupId: groupId ?? this.groupId,
      eventId: eventId ?? this.eventId,
      assigneeId: assigneeId ?? this.assigneeId,
      eventEmoji: eventEmoji ?? this.eventEmoji,
      weekday: weekday ?? this.weekday,
      days: days ?? this.days,
      hours: hours ?? this.hours,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper method to get the properly formatted action description based on type
  String get formattedDescription {
    switch (type) {
      case ActionType.voteDate:
        return 'Vote a date';
      case ActionType.votePlace:
        return 'Vote a place';
      case ActionType.confirmAttendance:
        return 'Confirm attendance';
      case ActionType.completeDetails:
        return 'Complete event details';
      case ActionType.addPhotos:
        return 'Add photos';
      default:
        return description;
    }
  }

  // Helper method to get deadline information
  String? get deadlineText {
    if (dueDate == null) return null;

    final now = DateTime.now();
    final difference = dueDate!.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    }

    final days = difference.inDays;
    final hours = difference.inHours;

    if (days > 0) {
      return '${days}d left';
    } else if (hours > 0) {
      return '${hours}h left';
    } else {
      return 'Due soon';
    }
  }

  // Helper method to get the deeplink for the action
  String? get deeplink {
    switch (type) {
      case ActionType.voteDate:
      case ActionType.votePlace:
      case ActionType.confirmAttendance:
      case ActionType.completeDetails:
        return eventId != null ? 'lazzo://event/$eventId' : null;
      case ActionType.addPhotos:
        return eventId != null ? 'lazzo://event/$eventId/uploads' : null;
      default:
        return eventId != null ? 'lazzo://event/$eventId' : null;
    }
  }
}
