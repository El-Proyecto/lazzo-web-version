/// Host-facing action types for inbox Actions tab.
/// These represent tasks the host should do to keep their events on track.
enum ActionType {
  /// Remind guests who are "maybe" or "pending" — CTA: Manage Guests
  remindMaybeVoters,

  /// Confirm the event — only shown 24h before start_datetime
  confirmEvent,

  /// Reschedule an expired event (end_datetime passed, needs new dates)
  rescheduleExpiredEvent,

  /// Review guest list — some guests are still "maybe" or "pending" — CTA: Manage Guests
  reviewGuests,

  /// Upload/add photos during the living phase — disappears when host has photos
  addPhotos,
}

enum ActionStatus { pending, completed, dismissed }

enum ActionPriority { low, medium, high, urgent }

class ActionEntity {
  final String id;
  final String title;
  final String subtitle;
  final ActionType type;
  final ActionStatus status;
  final ActionPriority priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? eventId;
  final String? eventName;
  final String? eventEmoji;

  /// Extra context: e.g. "3 guests haven't voted", "Missing date & location"
  final String? contextInfo;
  final Map<String, dynamic>? metadata;

  const ActionEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    this.eventId,
    this.eventName,
    this.eventEmoji,
    this.contextInfo,
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
    String? subtitle,
    ActionType? type,
    ActionStatus? status,
    ActionPriority? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    String? eventId,
    String? eventName,
    String? eventEmoji,
    String? contextInfo,
    Map<String, dynamic>? metadata,
  }) {
    return ActionEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      eventEmoji: eventEmoji ?? this.eventEmoji,
      contextInfo: contextInfo ?? this.contextInfo,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Icon emoji for the action type
  String get typeEmoji {
    switch (type) {
      case ActionType.remindMaybeVoters:
        return '🗳️';
      case ActionType.confirmEvent:
        return '✅';
      case ActionType.rescheduleExpiredEvent:
        return '📅';
      case ActionType.reviewGuests:
        return '👥';
      case ActionType.addPhotos:
        return '📸';
    }
  }

  /// Human-readable deadline text
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
      final minutes = difference.inMinutes;
      return minutes > 0 ? '${minutes}m left' : 'Due soon';
    }
  }
}
