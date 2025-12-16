import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(Supabase.instance.client);
});

/// Service for programmatic notification creation
/// Uses V2 secure RPC (create_notification_secure) with server-side filtering
/// Most notifications are created automatically via database triggers,
/// but this service provides methods for manual/edge case notifications.
///
/// Note: title/description removed (i18n handled client-side via ARB files)
class NotificationService {
  final SupabaseClient _client;

  NotificationService(this._client);

  /// Send group invite notification
  /// Triggered when: User invites another user to join a group
  /// Category: PUSH (urgent action required)
  Future<String?> sendGroupInvite({
    required String recipientUserId,
    required String inviterName,
    required String groupName,
    required String groupId,
  }) async {
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'groupInviteReceived',
      'p_category': 'push',
      'p_priority': 'high',
      'p_deeplink': 'lazzo://groups/$groupId',
      'p_group_id': groupId,
      'p_user_name': inviterName,
      'p_group_name': groupName,
    });
  }

  /// Send payment request notification
  /// Triggered when: User requests payment from another user
  Future<String?> sendPaymentRequest({
    required String recipientUserId,
    required String requesterName,
    required String amount,
    required String eventId,
    String? eventEmoji,
    String? eventName,
    String? note,
  }) async {
    return await _client.rpc('create_notification_if_not_duplicate', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'paymentsRequest',
      'p_title': 'Payment Request',
      'p_description': '{user} requested **{amount}** for {note}.',
      'p_category': 'push',
      'p_priority': 'high',
      'p_action_text': 'Pay Now',
      'p_deeplink': 'lazzo://events/$eventId/expenses',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': requesterName,
      'p_event_name': eventName,
      'p_amount': amount,
      'p_note': note ?? 'expense',
    });
  }

  /// Send expense added notification (you owe money)
  /// Usually triggered by database trigger, but can be called manually
  Future<String?> sendExpenseAddedYouOwe({
    required String recipientUserId,
    required String creatorName,
    required String amount,
    required String eventId,
    String? eventEmoji,
    String? eventName,
  }) async {
    return await _client.rpc('create_notification_if_not_duplicate', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'paymentsAddedYouOwe',
      'p_title': 'New Expense',
      'p_description': '{user} added an expense. You owe **{amount}**.',
      'p_category': 'push',
      'p_priority': 'high',
      'p_action_text': 'View Details',
      'p_deeplink': 'lazzo://events/$eventId/expenses',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': creatorName,
      'p_event_name': eventName,
      'p_amount': amount,
    });
  }

  /// Send payment received notification
  /// Triggered when: Someone pays you back for an expense
  Future<String?> sendPaymentReceived({
    required String recipientUserId,
    required String payerName,
    required String amount,
    required String eventId,
    String? eventEmoji,
    String? eventName,
  }) async {
    return await _client.rpc('create_notification_if_not_duplicate', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'paymentsPaidYou',
      'p_title': 'Payment Received',
      'p_description': '{user} paid you **{amount}**.',
      'p_category': 'notifications',
      'p_priority': 'medium',
      'p_action_text': 'View Details',
      'p_deeplink': 'lazzo://events/$eventId/expenses',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': payerName,
      'p_event_name': eventName,
      'p_amount': amount,
    });
  }

  /// Send event starts soon notification
  /// Triggered by: Scheduled job (15 min before event)
  Future<String?> sendEventStartsSoon({
    required String recipientUserId,
    required String eventName,
    required String eventId,
    required int minsUntilStart,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_if_not_duplicate', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'eventStartsSoon',
      'p_title': 'Event Starting Soon',
      'p_description': '**{event}** starts in {mins} min.',
      'p_category': 'push',
      'p_priority': 'high',
      'p_action_text': 'View Event',
      'p_deeplink': 'lazzo://events/$eventId',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_event_name': eventName,
      'p_mins': minsUntilStart.toString(),
    });
  }

  /// Send event live notification
  /// Triggered by: Event status changes to 'living'
  Future<String?> sendEventLive({
    required String recipientUserId,
    required String eventName,
    required String eventId,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_if_not_duplicate', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'eventLive',
      'p_title': 'Event is Live',
      'p_description': '**{event}** is live now.',
      'p_category': 'push',
      'p_priority': 'high',
      'p_action_text': 'Join Now',
      'p_deeplink': 'lazzo://events/$eventId',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_event_name': eventName,
    });
  }

  /// Send event extended notification
  /// Triggered when: Host extends event duration
  Future<String?> sendEventExtended({
    required String recipientUserId,
    required String eventName,
    required String eventId,
    required int additionalHours,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_if_not_duplicate', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'eventExtended',
      'p_title': 'Event Extended',
      'p_description': '**{event}** extended by {hours} hours.',
      'p_category': 'push',
      'p_priority': 'medium',
      'p_action_text': 'View Event',
      'p_deeplink': 'lazzo://events/$eventId',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_event_name': eventName,
      'p_hours': additionalHours.toString(),
    });
  }

  /// Send uploads open notification
  /// Triggered when: Event ends and photo upload window opens
  Future<String?> sendUploadsOpen({
    required String recipientUserId,
    required String eventName,
    required String eventId,
    required int hoursRemaining,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_if_not_duplicate', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'uploadsOpen',
      'p_title': 'Uploads Open',
      'p_description': 'Upload photos for **{event}**. {hours} hours left.',
      'p_category': 'push',
      'p_priority': 'medium',
      'p_action_text': 'Upload Now',
      'p_deeplink': 'lazzo://events/$eventId/upload',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_event_name': eventName,
      'p_hours': hoursRemaining.toString(),
    });
  }

  /// Send uploads closing notification
  /// Triggered by: Scheduled job (1 hour before upload deadline)
  Future<String?> sendUploadsClosing({
    required String recipientUserId,
    required String eventName,
    required String eventId,
    required int minsRemaining,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_if_not_duplicate', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'uploadsClosing',
      'p_title': 'Uploads Closing',
      'p_description': 'Last chance! Upload photos for **{event}**. {mins} min left.',
      'p_category': 'push',
      'p_priority': 'high',
      'p_action_text': 'Upload Now',
      'p_deeplink': 'lazzo://events/$eventId/upload',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_event_name': eventName,
      'p_mins': minsRemaining.toString(),
    });
  }

  /// Send memory ready notification
  /// Triggered when: Memory processing completes for an event
  Future<String?> sendMemoryReady({
    required String recipientUserId,
    required String eventName,
    required String eventId,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_if_not_duplicate', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'memoryReady',
      'p_title': 'Memory Ready',
      'p_description': 'Your memory for **{event}** is ready to view.',
      'p_category': 'push',
      'p_priority': 'medium',
      'p_action_text': 'View Memory',
      'p_deeplink': 'lazzo://events/$eventId/memory',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_event_name': eventName,
    });
  }

  /// Send chat mention notification
  /// Triggered when: User is @mentioned in event chat
  Future<String?> sendChatMention({
    required String recipientUserId,
    required String mentionerName,
    required String eventName,
    required String eventId,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_if_not_duplicate', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'chatMention',
      'p_title': 'Mentioned in Chat',
      'p_description': '{user} mentioned you in **{event}** chat.',
      'p_category': 'push',
      'p_priority': 'medium',
      'p_action_text': 'View Chat',
      'p_deeplink': 'lazzo://events/$eventId/chat',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': mentionerName,
      'p_event_name': eventName,
    });
  }

  /// Send new login notification
  /// Triggered when: User logs in from a new device
  Future<String?> sendNewLogin({
    required String recipientUserId,
    required String deviceName,
    required String location,
  }) async {
    return await _client.rpc('create_notification_if_not_duplicate', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'securityNewLogin',
      'p_title': 'New Login',
      'p_description': 'New login from {device} in {place}.',
      'p_category': 'push',
      'p_priority': 'high',
      'p_action_text': 'Review',
      'p_deeplink': 'lazzo://settings/security',
      'p_device': deviceName,
      'p_place': location,
    });
  }

  /// Send event created notification (feed)
  /// Usually triggered by database trigger, but can be called manually
  Future<String?> sendEventCreated({
    required String recipientUserId,
    required String creatorName,
    required String eventName,
    required String groupName,
    required String eventId,
    required String groupId,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_if_not_duplicate', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'eventCreated',
      'p_title': 'New Event',
      'p_description': 'New event **{event}** in **{group}**.',
      'p_category': 'notifications',
      'p_priority': 'medium',
      'p_deeplink': 'lazzo://events/$eventId',
      'p_group_id': groupId,
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': creatorName,
      'p_group_name': groupName,
      'p_event_name': eventName,
    });
  }

  /// Send event date confirmed notification
  /// Triggered when: Event date is set/confirmed
  Future<String?> sendEventDateSet({
    required String recipientUserId,
    required String eventName,
    required String eventId,
    required String date,
    required String time,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_if_not_duplicate', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'eventDateSet',
      'p_title': 'Date Confirmed',
      'p_description': 'Date confirmed for **{event}**: {date}, {time}.',
      'p_category': 'notifications',
      'p_priority': 'medium',
      'p_deeplink': 'lazzo://events/$eventId',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_event_name': eventName,
      'p_date': date,
      'p_time': time,
    });
  }

  /// Send event location set notification
  /// Triggered when: Event location is set/confirmed
  Future<String?> sendEventLocationSet({
    required String recipientUserId,
    required String eventName,
    required String eventId,
    required String locationName,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_if_not_duplicate', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'eventLocationSet',
      'p_title': 'Location Confirmed',
      'p_description': 'Location set for **{event}**: {place}.',
      'p_category': 'notifications',
      'p_priority': 'medium',
      'p_deeplink': 'lazzo://events/$eventId',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_event_name': eventName,
      'p_place': locationName,
    });
  }
}

