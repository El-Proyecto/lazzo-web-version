enum ActivityType { vote, rsvp, payment, taskAssignment, eventPreparation }

enum ActivityStatus { pending, completed, overdue, cancelled }

enum ActivityPriority { low, medium, high, urgent }

class ActivityEntity {
  final String id;
  final String title;
  final String description;
  final ActivityType type;
  final ActivityStatus status;
  final ActivityPriority priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? groupId;
  final String? eventId;
  final String? assigneeId;
  final Map<String, dynamic>? metadata;

  const ActivityEntity({
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
    this.metadata,
  });

  Duration? get timeLeft {
    if (dueDate == null) return null;
    final now = DateTime.now();
    return dueDate!.isAfter(now) ? dueDate!.difference(now) : null;
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status == ActivityStatus.pending;
  }

  ActivityEntity copyWith({
    String? id,
    String? title,
    String? description,
    ActivityType? type,
    ActivityStatus? status,
    ActivityPriority? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    String? groupId,
    String? eventId,
    String? assigneeId,
    Map<String, dynamic>? metadata,
  }) {
    return ActivityEntity(
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
      metadata: metadata ?? this.metadata,
    );
  }
}
