import 'package:lazzo/core/utils/date_utils.dart';

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
  final String? eventId;
  final String? eventEmoji;
  final String? userName;
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
    required this.type,
    required this.category,
    required this.priority,
    required this.createdAt,
    required this.isRead,
    this.actionText,
    this.actionUrl,
    this.deeplink,
    this.eventId,
    this.eventEmoji,
    this.userName,
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
      // title & description removed - V2 doesn't have these fields
      type: json['type'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String? ?? 'medium',
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      actionText: json['action_text'] as String?,
      actionUrl: json['action_url'] as String?,
      deeplink: json['deeplink'] as String?,
      eventId: json['event_id'] as String?,
      eventEmoji: json['event_emoji'] as String?,
      userName: json['user_name'] as String?,
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
      // title & description removed - V2 doesn't have these fields
      'type': type,
      'category': category,
      'priority': priority,
      'created_at': createdAt.toSupabaseIso8601String(),
      'is_read': isRead,
      'action_text': actionText,
      'action_url': actionUrl,
      'deeplink': deeplink,
      'event_id': eventId,
      'event_emoji': eventEmoji,
      'user_name': userName,
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
    // Generate temporary title/description (will be replaced by i18n in UI)
    final tempTitle = _generateTitle();
    final tempDescription = _generateDescription();

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
      eventId: eventId,
      eventEmoji: eventEmoji,
      userName: userName,
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

  // Temporary title generation (to be replaced by i18n)
  String _generateTitle() {
    switch (type) {
      // PUSH notifications
      // LAZZO 2.0: groupInviteReceived removed
      case 'eventStartsSoon':
        return 'Event Starting Soon';
      case 'eventLive':
        return 'Event Live';
      case 'eventEndsSoon':
        return 'Event Ending Soon';
      case 'eventExtended':
        return 'Event Extended';
      case 'uploadsOpen':
        return 'Uploads Open';
      case 'uploadsClosing':
        return 'Uploads Closing Soon';
      case 'memoryReady':
        return 'Memory Ready';
      case 'paymentsRequest':
        return 'Payment Request';
      case 'paymentsAddedYouOwe':
        return 'New Expense';
      case 'paymentsPaidYou':
        return 'Payment Received';
      case 'chatMention':
        return 'Mentioned in Chat';
      case 'securityNewLogin':
        return 'New Login';

      // NOTIFICATIONS (feed)
      // LAZZO 2.0: groupInviteAccepted, groupMemberAdded, groupRenamed, groupPhotoChanged removed
      case 'eventCreated':
        return 'New Event';
      case 'eventDateSet':
        return 'Event Date Set';
      case 'eventLocationSet':
        return 'Event Location Set';
      case 'eventDetailsUpdated':
        return 'Event Updated';
      case 'eventCanceled':
        return 'Event Canceled';
      case 'eventRestored':
        return 'Event Restored';
      case 'eventConfirmed':
        return 'Event Confirmed';
      case 'suggestionAdded':
        return 'New Suggestion';
      case 'dateSuggestionAdded':
        return 'Date Suggested';
      case 'locationSuggestionAdded':
        return 'Location Suggested';
      case 'rsvpUpdated':
        return 'RSVP Updated';
      case 'eventRsvpReminder':
        return 'Event Starting Soon';
      case 'paymentsReceived':
        return 'Payment Received';
      case 'memoryShared':
        return 'Memory Shared';

      // ACTIONS (to-dos)
      case 'voteDate':
        return 'Vote on Date';
      case 'votePlace':
        return 'Vote on Place';
      case 'confirmAttendance':
        return 'Confirm Attendance';
      case 'completeDetails':
        return 'Complete Event Details';
      case 'addPhotos':
        return 'Add Photos';

      default:
        return 'Notification';
    }
  }

  // Temporary description generation (to be replaced by i18n)
  String _generateDescription() {
    switch (type) {
      // PUSH notifications
      // LAZZO 2.0: groupInviteReceived removed
      case 'eventStartsSoon':
        return '{event} starts in {mins} min!';
      case 'eventLive':
        return '{event} is live now.';
      case 'eventEndsSoon':
        return '{event} ends in {mins} min.';
      case 'eventExtended':
        return '{event} was extended by {hours}h.';
      case 'uploadsOpen':
        return 'Add your photos to {event} · {hours}h left.';
      case 'uploadsClosing':
        return 'Last call to add photos to {event} · {mins} min left.';
      case 'memoryReady':
        return '{event} memory is ready to view!';
      case 'paymentsRequest':
        return '{user} requested {amount} for {note}.';
      case 'paymentsAddedYouOwe':
        return '{user} added the expense "{note}". You owe {amount}.';
      case 'paymentsAddedOwesYou':
        return '{user} added the expense "{note}". Someone owes you {amount}.';
      case 'paymentsPaidYou':
        return '{user} paid you {amount}.';
      case 'paymentReceived':
        return '{user} paid you {amount}.';
      case 'chatMention':
        return '{user} mentioned you in chat.';
      case 'chatMessage':
        return '{user}: {note}';
      case 'securityNewLogin':
        return 'New sign-in on {device}. Was this you?';

      // NOTIFICATIONS (feed)
      // LAZZO 2.0: groupInviteAccepted, groupMemberAdded, groupRenamed, groupPhotoChanged removed
      case 'eventCreated':
        return '{user} created {event}.';
      case 'eventDateSet':
        return '{event} is set for {date} at {time}.';
      case 'eventCanceled':
        return '{event} was canceled.';
      case 'eventRestored':
        return '{event} is back on.';
      case 'eventConfirmed':
        return '{event} confirmed for {date} at {time}.';
      case 'rsvpUpdated':
        return '{user} is {note} to {event}.';
      case 'suggestionAdded':
        return '{user} suggested {place} for {event}.';
      case 'dateSuggestionAdded':
        return '{user} suggested {date} at {time} for {event}.';
      case 'locationSuggestionAdded':
        return '{user} suggested {place} for {event}.';
      case 'paymentsReceived':
        return '{user} paid you {amount}.';
      case 'eventRsvpReminder':
        return 'Don\'t forget to confirm your attendance for {event} starting in {mins} min!';
      case 'memoryShared':
        return '{user} shared a memory from {event} with you.';

      // ACTIONS (to-dos)
      case 'voteDate':
        return 'Vote on a date for {event} · closes {date}';
      case 'votePlace':
        return 'Vote on a place for {event} · closes {date}';
      case 'confirmAttendance':
        return 'Confirm your attendance for {event} · {date}d left';
      case 'completeDetails':
        return 'Complete event details (date/location) for {event}';
      case 'addPhotos':
        return 'Add your photos to {event} · {hours}h left';

      default:
        return 'You have a new notification';
    }
  }

  NotificationType _parseNotificationType(String type) {
    switch (type) {
      // PUSH (13 types)
      // LAZZO 2.0: groupInviteReceived removed
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
      case 'paymentsAddedOwesYou':
        return NotificationType.paymentsAddedOwesYou;
      case 'paymentsPaidYou':
        return NotificationType.paymentsPaidYou;
      case 'chatMention':
        return NotificationType.chatMention;
      case 'chatMessage':
        return NotificationType.chatMessage;
      case 'securityNewLogin':
        return NotificationType.securityNewLogin;

      // NOTIFICATIONS (12 types - removed eventLocationSet, eventDetailsUpdated)
      // LAZZO 2.0: groupInviteAccepted, groupMemberAdded, groupRenamed, groupPhotoChanged removed
      case 'eventCreated':
        return NotificationType.eventCreated;
      case 'eventDateSet':
        return NotificationType.eventDateSet;
      case 'eventCanceled':
        return NotificationType.eventCanceled;
      case 'eventRestored':
        return NotificationType.eventRestored;
      case 'eventConfirmed':
        return NotificationType.eventConfirmed;
      case 'suggestionAdded':
        return NotificationType.suggestionAdded;
      case 'dateSuggestionAdded':
        return NotificationType.dateSuggestionAdded;
      case 'locationSuggestionAdded':
        return NotificationType.locationSuggestionAdded;
      case 'rsvpUpdated':
        return NotificationType.rsvpUpdated;
      case 'paymentsReceived':
        return NotificationType.paymentsReceived;
      case 'eventRsvpReminder':
        return NotificationType.eventRsvpReminder;
      case 'memoryShared':
        return NotificationType.memoryShared;

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
