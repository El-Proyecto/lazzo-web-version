enum NotificationType { groupInvite, eventUpdate, paymentRequest, general }

enum NotificationPriority { low, medium, high }

class NotificationEntity {
  final String id;
  final String title;
  final String description;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime createdAt;
  final bool isRead;
  final String? actionText;
  final String? actionUrl;
  final String? groupId;
  final String? eventId;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.isRead = false,
    this.actionText,
    this.actionUrl,
    this.groupId,
    this.eventId,
  });

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? description,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? createdAt,
    bool? isRead,
    String? actionText,
    String? actionUrl,
    String? groupId,
    String? eventId,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionText: actionText ?? this.actionText,
      actionUrl: actionUrl ?? this.actionUrl,
      groupId: groupId ?? this.groupId,
      eventId: eventId ?? this.eventId,
    );
  }
}
