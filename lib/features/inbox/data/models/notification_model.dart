import '../../domain/entities/notification_entity.dart';

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final String category;
  final String priority;
  final DateTime createdAt;
  final bool isRead;
  final String? actionText;
  final String? actionUrl;
  final String? deeplink;
  final String? groupId;
  final String? eventId;
  final String? eventEmoji;
  final String? userName;
  final String? groupName;
  final String? eventName;
  final String? amount;
  final String? hours;
  final String? mins;
  final String? date;
  final String? time;
  final String? place;
  final String? device;
  final String? note;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.priority,
    required this.createdAt,
    required this.isRead,
    this.actionText,
    this.actionUrl,
    this.deeplink,
    this.groupId,
    this.eventId,
    this.eventEmoji,
    this.userName,
    this.groupName,
    this.eventName,
    this.amount,
    this.hours,
    this.mins,
    this.date,
    this.time,
    this.place,
    this.device,
    this.note,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String? ?? 'medium',
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      actionText: json['action_text'] as String?,
      actionUrl: json['action_url'] as String?,
      deeplink: json['deeplink'] as String?,
      groupId: json['group_id'] as String?,
      eventId: json['event_id'] as String?,
      eventEmoji: json['event_emoji'] as String?,
      userName: json['user_name'] as String?,
      groupName: json['group_name'] as String?,
      eventName: json['event_name'] as String?,
      amount: json['amount'] as String?,
      hours: json['hours'] as String?,
      mins: json['mins'] as String?,
      date: json['date'] as String?,
      time: json['time'] as String?,
      place: json['place'] as String?,
      device: json['device'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'action_text': actionText,
      'action_url': actionUrl,
      'deeplink': deeplink,
      'group_id': groupId,
      'event_id': eventId,
      'event_emoji': eventEmoji,
      'user_name': userName,
      'group_name': groupName,
      'event_name': eventName,
      'amount': amount,
      'hours': hours,
      'mins': mins,
      'date': date,
      'time': time,
      'place': place,
      'device': device,
      'note': note,
    };
  }

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      title: title,
      description: description,
      type: _parseNotificationType(type),
      category: _parseCategory(category),
      priority: _parsePriority(priority),
      createdAt: createdAt,
      isRead: isRead,
      actionText: actionText,
      actionUrl: actionUrl,
      deeplink: deeplink,
      groupId: groupId,
      eventId: eventId,
      eventEmoji: eventEmoji,
      userName: userName,
      groupName: groupName,
      eventName: eventName,
      amount: amount,
      hours: hours,
      mins: mins,
      date: date,
      time: time,
      place: place,
      device: device,
      note: note,
    );
  }

  NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'groupInviteReceived':
        return NotificationType.groupInviteReceived;
      case 'eventStartsSoon':
        return NotificationType.eventStartsSoon;
      case 'eventLive':
        return NotificationType.eventLive;
      case 'eventEndsSoon':
        return NotificationType.eventEndsSoon;
      case 'eventExtended':
        return NotificationType.eventExtended;
      case 'uploadsOpen':
        return NotificationType.uploadsOpen;
      case 'uploadsClosing':
        return NotificationType.uploadsClosing;
      case 'memoryReady':
        return NotificationType.memoryReady;
      case 'paymentsRequest':
        return NotificationType.paymentsRequest;
      case 'paymentsAddedYouOwe':
        return NotificationType.paymentsAddedYouOwe;
      case 'paymentsPaidYou':
        return NotificationType.paymentsPaidYou;
      case 'chatMention':
        return NotificationType.chatMention;
      case 'securityNewLogin':
        return NotificationType.securityNewLogin;
      case 'groupInviteAccepted':
        return NotificationType.groupInviteAccepted;
      case 'groupRenamed':
        return NotificationType.groupRenamed;
      case 'groupPhotoChanged':
        return NotificationType.groupPhotoChanged;
      case 'eventCreated':
        return NotificationType.eventCreated;
      case 'eventDateSet':
        return NotificationType.eventDateSet;
      case 'eventLocationSet':
        return NotificationType.eventLocationSet;
      case 'eventDetailsUpdated':
        return NotificationType.eventDetailsUpdated;
      case 'eventCanceled':
        return NotificationType.eventCanceled;
      case 'eventRestored':
        return NotificationType.eventRestored;
      case 'eventConfirmed':
        return NotificationType.eventConfirmed;
      case 'suggestionAdded':
        return NotificationType.suggestionAdded;
      default:
        return NotificationType.general;
    }
  }

  NotificationCategory _parseCategory(String category) {
    switch (category) {
      case 'push':
        return NotificationCategory.push;
      case 'notifications':
        return NotificationCategory.notifications;
      case 'actions':
        return NotificationCategory.actions;
      default:
        return NotificationCategory.notifications;
    }
  }

  NotificationPriority _parsePriority(String priority) {
    switch (priority) {
      case 'high':
        return NotificationPriority.high;
      case 'medium':
        return NotificationPriority.medium;
      case 'low':
        return NotificationPriority.low;
      default:
        return NotificationPriority.medium;
    }
  }
}
