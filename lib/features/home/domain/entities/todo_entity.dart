/// To-do entity for home page
/// Compact representation of pending actions for the user
class TodoEntity {
  final String id;
  final String actionName; // e.g., "Vote a date"
  final String eventEmoji; // e.g., "🍽️"
  final String eventName; // e.g., "Friday Dinner"
  final String groupName; // e.g., "Dinner Group"
  final DateTime? deadline;

  const TodoEntity({
    required this.id,
    required this.actionName,
    required this.eventEmoji,
    required this.eventName,
    required this.groupName,
    this.deadline,
  });

  /// Time left until deadline
  Duration? get timeLeft {
    if (deadline == null) return null;
    final now = DateTime.now();
    return deadline!.isAfter(now) ? deadline!.difference(now) : null;
  }

  /// Whether the todo is overdue
  bool get isOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!);
  }

  /// Formatted deadline text
  String? get deadlineText {
    if (deadline == null) return null;

    final now = DateTime.now();
    final difference = deadline!.difference(now);

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
}
