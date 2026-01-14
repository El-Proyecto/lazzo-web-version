// Based on notifications_catalog.md
enum NotificationCategory { push, notifications, actions }

// PUSH (with in-app feed entry) - Essential, low-noise changes of state
enum NotificationPushType {
  groupInviteReceived,
  eventStartsSoon,
  eventLive,
  eventEndsSoon,
  eventExtended,
  uploadsOpen,
  uploadsClosing,
  memoryReady,
  paymentsRequest,
  paymentsAddedYouOwe,
  paymentsPaidYou,
  chatMention,
  securityNewLogin,
}

// NOTIFICATIONS (feed) - Informational updates
enum NotificationFeedType {
  groupInviteAccepted,
  groupRenamed,
  groupPhotoChanged,
  eventCreated,
  eventDateSet,
  eventLocationSet,
  eventDetailsUpdated,
  eventCanceled,
  eventRestored,
  eventConfirmed,
  suggestionAdded,
}

// ACTIONS - Items the user can/should resolve
enum ActionNotificationType {
  voteDate,
  votePlace,
  confirmAttendance,
  completeDetails,
  addPhotos,
}

enum NotificationType {
  // Legacy types for backwards compatibility
  groupInvite,
  eventUpdate,
  paymentRequest,
  general,
  // New specific types based on catalog
  groupInviteReceived,
  eventStartsSoon,
  eventLive,
  eventEndsSoon,
  eventExtended,
  uploadsOpen,
  uploadsClosing,
  memoryReady,
  paymentsRequest,
  paymentsAddedYouOwe,
  paymentsAddedOwesYou, // NEW: Split from paymentsAddedYouOwe
  paymentsPaidYou,
  chatMention,
  chatMessage, // NEW: Chat messages notification
  securityNewLogin,
  groupInviteAccepted,
  groupRenamed,
  groupPhotoChanged,
  eventCreated,
  eventDateSet,
  eventConfirmed,
  eventCanceled,
  eventRestored,
  suggestionAdded,
  dateSuggestionAdded,
  rsvpUpdated,
  memoryShared,
  // Removed: eventLocationSet, eventDetailsUpdated (not in updated spec)
}

enum NotificationPriority { low, medium, high }

class NotificationEntity {
  final String id;
  // V2: title/description generated on client via i18n (not stored in DB)
  final String title; // Temporary until i18n implemented
  final String description; // Temporary until i18n implemented
  final NotificationType type;
  final NotificationCategory category;
  final NotificationPriority priority;
  final DateTime createdAt;
  final bool isRead;
  final String? actionText;
  final String? actionUrl;
  final String? deeplink; // New field for deeplinks
  final String? groupId;
  final String? eventId;
  final String? eventEmoji;
  final String? userName; // For {user} placeholder
  final String? groupName; // For {group} placeholder
  final String? eventName; // For {event} placeholder
  final String? amount; // For {amount} placeholder
  final String? hours; // For {hours} placeholder
  final String? mins; // For {mins} placeholder
  final String? date; // For {date} placeholder
  final String? time; // For {time} placeholder
  final String? place; // For {place} placeholder
  final String? device; // For {device} placeholder
  final String? note; // For payment notes
  final String? expenseId; // Link to expense for payment notifications
  final String? expenseName; // For expense name in payment notifications
  final String? personName; // For person who owes in payment notifications

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.priority,
    required this.createdAt,
    this.isRead = false,
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
    this.expenseName,
    this.personName,
  });

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? description,
    NotificationType? type,
    NotificationCategory? category,
    NotificationPriority? priority,
    DateTime? createdAt,
    bool? isRead,
    String? actionText,
    String? actionUrl,
    String? deeplink,
    String? groupId,
    String? eventId,
    String? eventEmoji,
    String? userName,
    String? groupName,
    String? eventName,
    String? amount,
    String? hours,
    String? mins,
    String? date,
    String? time,
    String? place,
    String? device,
    String? note,
    String? expenseId,
    String? expenseName,
    String? personName,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionText: actionText ?? this.actionText,
      actionUrl: actionUrl ?? this.actionUrl,
      deeplink: deeplink ?? this.deeplink,
      groupId: groupId ?? this.groupId,
      eventId: eventId ?? this.eventId,
      eventEmoji: eventEmoji ?? this.eventEmoji,
      userName: userName ?? this.userName,
      groupName: groupName ?? this.groupName,
      eventName: eventName ?? this.eventName,
      amount: amount ?? this.amount,
      hours: hours ?? this.hours,
      mins: mins ?? this.mins,
      date: date ?? this.date,
      time: time ?? this.time,
      place: place ?? this.place,
      device: device ?? this.device,
      note: note ?? this.note,
      expenseId: expenseId ?? this.expenseId,
      expenseName: expenseName ?? this.expenseName,
      personName: personName ?? this.personName,
    );
  }

  // Helper method to get formatted message with placeholders replaced
  String get formattedMessage {
    String message = description;

    if (userName != null) {
      message = message.replaceAll('{user}', '**$userName**');
    }
    if (groupName != null) {
      message = message.replaceAll('{group}', '**$groupName**');
    }
    if (eventName != null) {
      message = message.replaceAll('{event}', '**$eventName**');
    }
    if (amount != null) {
      // Ensure amount always has € symbol at the end
      final formattedAmount = amount!.endsWith('€') ? amount! : '$amount€';
      message = message.replaceAll('{amount}', '**$formattedAmount**');
    }
    if (hours != null) message = message.replaceAll('{hours}', '**$hours**');
    if (mins != null) message = message.replaceAll('{mins}', '**$mins**');
    if (date != null) message = message.replaceAll('{date}', '**$date**');
    if (time != null) message = message.replaceAll('{time}', '**$time**');
    if (place != null) message = message.replaceAll('{place}', '**$place**');
    if (device != null) message = message.replaceAll('{device}', '**$device**');
    if (note != null) message = message.replaceAll('{note}', note!);
    if (expenseName != null) {
      message = message.replaceAll('{expense_name}', '**$expenseName**');
    }
    if (personName != null) {
      message = message.replaceAll('{person_name}', '**$personName**');
    }

    return message;
  }

  // Helper method to get the deeplink based on type
  String? get resolvedDeeplink {
    if (deeplink != null) return deeplink;

    // Generate deeplink based on type and available IDs
    switch (type) {
      case NotificationType.groupInviteReceived:
      case NotificationType.groupInviteAccepted:
      case NotificationType.groupRenamed:
      case NotificationType.groupPhotoChanged:
        return groupId != null ? 'lazzo://group/$groupId' : null;

      case NotificationType.eventStartsSoon:
      case NotificationType.eventLive:
      case NotificationType.eventEndsSoon:
      case NotificationType.eventExtended:
      case NotificationType.eventCreated:
      case NotificationType.eventDateSet:
      case NotificationType.eventRestored:
      case NotificationType.eventConfirmed:
      case NotificationType.suggestionAdded:
      case NotificationType.chatMention:
      case NotificationType.chatMessage:
        return eventId != null ? 'lazzo://event/$eventId' : null;

      case NotificationType.uploadsOpen:
      case NotificationType.uploadsClosing:
        return eventId != null ? 'lazzo://event/$eventId/uploads' : null;

      case NotificationType.paymentsRequest:
      case NotificationType.paymentsAddedYouOwe:
      case NotificationType.paymentsAddedOwesYou:
      case NotificationType.paymentsPaidYou:
        return 'lazzo://payments';

      case NotificationType.securityNewLogin:
        return 'lazzo://profile/security';

      case NotificationType.eventCanceled:
        return groupId != null ? 'lazzo://group/$groupId' : null;

      default:
        return null;
    }
  }
}
