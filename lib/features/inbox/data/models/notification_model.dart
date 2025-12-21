import '../../domain/entities/notification_entity.dart';

class NotificationModel {
  final String id;
  // title & description removed - V2 uses i18n on client side
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
  final String? expenseId; // ✅ Link to expense for payment notifications

  const NotificationModel({
    required this.id,
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
    this.expenseId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    print('[NotificationModel] 📝 Parsing JSON: ${json.keys.toList()}');
    
    return NotificationModel(
      id: json['id'] as String,
      // title & description removed - V2 doesn't have these fields
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
      expenseId: json['expense_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // title & description removed - V2 doesn't have these fields
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
      'expense_id': expenseId,
    };
  }

  NotificationEntity toEntity() {
    print('[NotificationModel] 🔄 Converting to entity: type=$type, category=$category');
    
    // Generate temporary title/description (will be replaced by i18n in UI)
    final tempTitle = _generateTitle();
    final tempDescription = _generateDescription();
    
    print('[NotificationModel] ✅ Generated title: $tempTitle');
    print('[NotificationModel] ✅ Generated description: $tempDescription');
    
    return NotificationEntity(
      id: id,
      title: tempTitle,
      description: tempDescription,
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
      expenseId: expenseId,
    );
  }

  // Temporary title generation (to be replaced by i18n)
  String _generateTitle() {
    switch (type) {
      // PUSH notifications
      case 'groupInviteReceived': return 'Group Invite';
      case 'eventStartsSoon': return 'Event Starting Soon';
      case 'eventLive': return 'Event Live';
      case 'eventEndsSoon': return 'Event Ending Soon';
      case 'eventExtended': return 'Event Extended';
      case 'uploadsOpen': return 'Uploads Open';
      case 'uploadsClosing': return 'Uploads Closing Soon';
      case 'memoryReady': return 'Memory Ready';
      case 'paymentsRequest': return 'Payment Request';
      case 'paymentsAddedYouOwe': return 'New Expense';
      case 'paymentsPaidYou': return 'Payment Received';
      case 'chatMention': return 'Mentioned in Chat';
      case 'securityNewLogin': return 'New Login';
      
      // NOTIFICATIONS (feed)
      case 'groupInviteAccepted': return 'Invite Accepted';
      case 'groupRenamed': return 'Group Renamed';
      case 'groupPhotoChanged': return 'Group Photo Changed';
      case 'eventCreated': return 'New Event';
      case 'eventDateSet': return 'Event Date Set';
      case 'eventLocationSet': return 'Event Location Set';
      case 'eventDetailsUpdated': return 'Event Updated';
      case 'eventCanceled': return 'Event Canceled';
      case 'eventRestored': return 'Event Restored';
      case 'eventConfirmed': return 'Event Confirmed';
      case 'suggestionAdded': return 'New Suggestion';
      
      // ACTIONS (to-dos)
      case 'voteDate': return 'Vote on Date';
      case 'votePlace': return 'Vote on Place';
      case 'confirmAttendance': return 'Confirm Attendance';
      case 'completeDetails': return 'Complete Event Details';
      case 'addPhotos': return 'Add Photos';
      
      default: return 'Notification';
    }
  }

  // Temporary description generation (to be replaced by i18n)
  String _generateDescription() {
    switch (type) {
      // PUSH notifications
      case 'groupInviteReceived':
        return '${userName ?? 'Someone'} invited you to join ${groupName ?? 'a group'}';
      case 'eventStartsSoon':
        return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} starts in ${mins ?? '?'} min.';
      case 'eventLive':
        return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} is live now.';
      case 'eventEndsSoon':
        return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} ends in ${mins ?? '?'} min.';
      case 'eventExtended':
        return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} was extended by ${mins ?? '?'} min.';
      case 'uploadsOpen':
        return 'Add your photos to ${eventEmoji ?? '🎉'} ${eventName ?? 'event'} · ${hours ?? '?'}h left.';
      case 'uploadsClosing':
        return 'Last call to add photos to ${eventEmoji ?? '🎉'} ${eventName ?? 'event'} · ${hours ?? '?'}h left.';
      case 'memoryReady':
        return 'Your memory for ${eventEmoji ?? '🎉'} ${eventName ?? 'event'} is ready to share.';
      case 'paymentsRequest':
        return '${userName ?? 'Someone'} requested ${amount ?? '?'}${note != null ? ' for $note' : ''}.';
      case 'paymentsAddedYouOwe':
        return '${userName ?? 'Someone'} added an expense in ${eventName ?? 'event'}. You owe ${amount ?? '?'}.';
      case 'paymentsPaidYou':
        return '${userName ?? 'Someone'} paid you ${amount ?? '?'}.';
      case 'chatMention':
        return '${userName ?? 'Someone'} mentioned you in ${eventEmoji ?? '🎉'} ${eventName ?? 'event'}.';
      case 'securityNewLogin':
        return 'New sign-in on ${device ?? 'unknown device'}. Was this you?';
      
      // NOTIFICATIONS (feed)
      case 'groupInviteAccepted':
        return '${userName ?? 'Someone'} joined ${groupName ?? 'a group'}.';
      case 'groupRenamed':
        return '${groupName ?? 'A group'} has a new name.';
      case 'groupPhotoChanged':
        return '${groupName ?? 'A group'} has a new photo.';
      case 'eventCreated':
        return 'New event ${eventEmoji ?? '🎉'} ${eventName ?? ''} in ${groupName ?? 'a group'}.';
      case 'eventDateSet':
        return 'Date confirmed for ${eventEmoji ?? '🎉'} ${eventName ?? 'event'}: ${date ?? '?'}, ${time ?? '?'}.';
      case 'eventLocationSet':
        return 'Location confirmed for ${eventEmoji ?? '🎉'} ${eventName ?? 'event'}: ${place ?? '?'}.';
      case 'eventDetailsUpdated':
        return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} was updated. Check the new details.';
      case 'eventCanceled':
        return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} was canceled.';
      case 'eventRestored':
        return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} is back on.';
      case 'eventConfirmed':
        return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} is confirmed to happen.';
      case 'suggestionAdded':
        return '${userName ?? 'Someone'} suggested ${place ?? date ?? 'something'} for ${eventName ?? 'event'}.';
      
      // ACTIONS (to-dos)
      case 'voteDate':
        return 'Vote on a date for ${eventName ?? 'event'} · closes ${date ?? 'soon'}';
      case 'votePlace':
        return 'Vote on a place for ${eventName ?? 'event'} · closes ${date ?? 'soon'}';
      case 'confirmAttendance':
        return 'Confirm your attendance for ${eventName ?? 'event'} · ${date ?? '?'}d left';
      case 'completeDetails':
        return 'Complete event details (date/location) for ${eventName ?? 'event'}';
      case 'addPhotos':
        return 'Add your photos to ${eventName ?? 'event'} · ${hours ?? '?'}h left';
      
      default:
        return 'You have a new notification';
    }
  }

  NotificationType _parseNotificationType(String type) {
    switch (type) {
      // PUSH (13 types)
      case 'groupInviteReceived': return NotificationType.groupInviteReceived;
      case 'eventStartsSoon': return NotificationType.eventStartsSoon;
      case 'eventLive': return NotificationType.eventLive;
      case 'eventEndsSoon': return NotificationType.eventEndsSoon;
      case 'eventExtended': return NotificationType.eventExtended;
      case 'uploadsOpen': return NotificationType.uploadsOpen;
      case 'uploadsClosing': return NotificationType.uploadsClosing;
      case 'memoryReady': return NotificationType.memoryReady;
      case 'paymentsRequest': return NotificationType.paymentsRequest;
      case 'paymentsAddedYouOwe': return NotificationType.paymentsAddedYouOwe;
      case 'paymentsPaidYou': return NotificationType.paymentsPaidYou;
      case 'chatMention': return NotificationType.chatMention;
      case 'securityNewLogin': return NotificationType.securityNewLogin;
      
      // NOTIFICATIONS (11 types)
      case 'groupInviteAccepted': return NotificationType.groupInviteAccepted;
      case 'groupRenamed': return NotificationType.groupRenamed;
      case 'groupPhotoChanged': return NotificationType.groupPhotoChanged;
      case 'eventCreated': return NotificationType.eventCreated;
      case 'eventDateSet': return NotificationType.eventDateSet;
      case 'eventLocationSet': return NotificationType.eventLocationSet;
      case 'eventDetailsUpdated': return NotificationType.eventDetailsUpdated;
      case 'eventCanceled': return NotificationType.eventCanceled;
      case 'eventRestored': return NotificationType.eventRestored;
      case 'eventConfirmed': return NotificationType.eventConfirmed;
      case 'suggestionAdded': return NotificationType.suggestionAdded;
      
      default: return NotificationType.general;
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
