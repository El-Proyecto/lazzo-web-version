import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(Supabase.instance.client);
});

/// Service for programmatic notification creation (V2 - Secure)
/// Uses create_notification_secure RPC with server-side filtering
/// Most notifications are created automatically via database triggers,
/// but this service provides methods for manual/edge case notifications.
///
/// Note: title/description removed (i18n handled client-side via ARB files)
class NotificationService {
  final SupabaseClient _client;

  NotificationService(this._client);

  // ==================== PUSH NOTIFICATIONS ====================
  // Urgent actions requiring immediate attention (phone notification + inbox)

  /// Send group invite notification
  /// Triggered when: User invites another user to join a group
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

  /// Send expense added notification (you owe money)
  /// Triggered when: Someone creates an expense where you owe money
  Future<String?> sendExpenseAddedYouOwe({
    required String recipientUserId,
    required String creatorName,
    required String expenseName,
    required String amount,
    required String eventId,
    required String expenseId,
    String? eventEmoji,
    String? eventName,
  }) async {
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'paymentsAddedYouOwe',
      'p_category': 'notifications',
      'p_priority': 'high',
      'p_deeplink': 'lazzo://events/$eventId/expenses',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': creatorName,
      'p_event_name': eventName,
      'p_note': expenseName,
      'p_amount': amount,
      'p_expense_id': expenseId,
    });
  }

  /// Send expense added notification (someone owes you)
  /// Triggered when: Someone creates an expense where another person owes you
  Future<String?> sendExpenseAddedOwesYou({
    required String recipientUserId,
    required String creatorName,
    required String expenseName,
    required String debtorName,
    required String amount,
    required String eventId,
    required String expenseId,
    String? eventEmoji,
    String? eventName,
  }) async {
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'paymentsAddedOwesYou',
      'p_category': 'notifications',
      'p_priority': 'high',
      'p_deeplink': 'lazzo://events/$eventId/expenses',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': creatorName,
      'p_event_name': eventName,
      'p_note': expenseName, // ✅ Use p_note for expense name
      'p_amount': amount,
      'p_expense_id': expenseId, // ✅ Add expense_id
      // Note: debtorName is shown in UI but stored in notification display logic
    });
  }

  /// Send payment request notification
  /// Triggered when: User requests payment from another user
  Future<String?> sendPaymentRequest({
    required String recipientUserId,
    required String requesterName,
    required String expenseName,
    required String amount,
    required String eventId,
    String? eventEmoji,
    String? eventName,
    String? note,
  }) async {
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'paymentsRequest',
      'p_category': 'actions',
      'p_priority': 'high',
      'p_deeplink': 'lazzo://events/$eventId/expenses',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': requesterName,
      'p_event_name': eventName,
      'p_expense_name': expenseName,
      'p_amount': amount,
      'p_note': note ?? 'expense',
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
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'eventStartsSoon',
      'p_category': 'push',
      'p_priority': 'high',
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
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'eventLive',
      'p_category': 'push',
      'p_priority': 'high',
      'p_deeplink': 'lazzo://events/$eventId',
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
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'chatMention',
      'p_category': 'push',
      'p_priority': 'medium',
      'p_deeplink': 'lazzo://events/$eventId/chat',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': mentionerName,
      'p_event_name': eventName,
    });
  }

  /// Send chat message notification
  /// Triggered when: New message in event chat (only if chat not muted)
  /// Note: Only send to other users, not sender
  Future<String?> sendChatMessage({
    required String recipientUserId,
    required String senderName,
    required String message,
    required String eventName,
    required String eventId,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'chatMessage',
      'p_category': 'push',
      'p_priority': 'medium',
      'p_deeplink': 'lazzo://events/$eventId/chat',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': senderName,
      'p_event_name': eventName,
      'p_message':
          message.length > 100 ? '${message.substring(0, 100)}...' : message,
    });
  }

  /// Send new login notification (security)
  /// Triggered when: User logs in from a new device
  Future<String?> sendNewLogin({
    required String recipientUserId,
    required String deviceName,
    required String location,
  }) async {
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'securityNewLogin',
      'p_category': 'push',
      'p_priority': 'high',
      'p_deeplink': 'lazzo://settings/security',
      'p_device': deviceName,
      'p_place': location,
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
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'uploadsClosing',
      'p_category': 'push',
      'p_priority': 'high',
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
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'memoryReady',
      'p_category': 'push',
      'p_priority': 'medium',
      'p_deeplink': 'lazzo://events/$eventId/memory',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_event_name': eventName,
    });
  }

  /// Send event ends soon notification
  /// Triggered by: Scheduled job (15 min before event ends)
  Future<String?> sendEventEndsSoon({
    required String recipientUserId,
    required String eventName,
    required String eventId,
    required int minsUntilEnd,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'eventEndsSoon',
      'p_category': 'push',
      'p_priority': 'high',
      'p_deeplink': 'lazzo://events/$eventId',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_event_name': eventName,
      'p_mins': minsUntilEnd.toString(),
    });
  }

  // ==================== NOTIFICATIONS (Inbox Only) ====================
  // Useful information but not urgent (inbox feed only)

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
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'eventCreated',
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
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'paymentsPaidYou',
      'p_category': 'notifications',
      'p_priority': 'medium',
      'p_deeplink': 'lazzo://events/$eventId/expenses',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': payerName,
      'p_event_name': eventName,
      'p_amount': amount,
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
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'eventExtended',
      'p_category': 'notifications',
      'p_priority': 'medium',
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
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'uploadsOpen',
      'p_category': 'notifications',
      'p_priority': 'medium',
      'p_deeplink': 'lazzo://events/$eventId/upload',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_event_name': eventName,
      'p_hours': hoursRemaining.toString(),
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
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'eventDateSet',
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

  /// Send RSVP updated notification
  /// Triggered when: Someone updates their RSVP (useful for host)
  Future<String?> sendRsvpUpdated({
    required String recipientUserId,
    required String userName,
    required String eventName,
    required String eventId,
    required String rsvpStatus, // 'going', 'maybe', 'cant_go'
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'rsvpUpdated',
      'p_category': 'notifications',
      'p_priority': 'low',
      'p_deeplink': 'lazzo://events/$eventId',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': userName,
      'p_event_name': eventName,
      'p_note': rsvpStatus,
    });
  }

  /// Send memory shared notification
  /// Triggered when: Someone shares a memory with you
  Future<String?> sendMemoryShared({
    required String recipientUserId,
    required String sharerName,
    required String eventName,
    required String eventId,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'memoryShared',
      'p_category': 'notifications',
      'p_priority': 'medium',
      'p_deeplink': 'lazzo://events/$eventId/memory',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': sharerName,
      'p_event_name': eventName,
    });
  }

  /// Send date suggestion added notification
  /// Triggered when: Someone suggests a new date for an event
  Future<String?> sendDateSuggestionAdded({
    required String recipientUserId,
    required String suggestorName,
    required String eventName,
    required String eventId,
    required String date,
    required String time,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'dateSuggestionAdded',
      'p_category': 'notifications',
      'p_priority': 'medium',
      'p_deeplink': 'lazzo://events/$eventId/planning',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': suggestorName,
      'p_event_name': eventName,
      'p_date': date,
      'p_time': time,
    });
  }

  /// Send event confirmed notification
  /// Triggered when: Event status changes to 'confirmed'
  Future<String?> sendEventConfirmed({
    required String recipientUserId,
    required String eventName,
    required String eventId,
    required String date,
    required String time,
    String? eventEmoji,
    String? locationName,
  }) async {
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'eventConfirmed',
      'p_category': 'notifications',
      'p_priority': 'high',
      'p_deeplink': 'lazzo://events/$eventId',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_event_name': eventName,
      'p_date': date,
      'p_time': time,
      'p_place': locationName,
    });
  }

  /// Send event canceled notification
  /// Triggered when: Event is canceled by host
  Future<String?> sendEventCanceled({
    required String recipientUserId,
    required String eventName,
    required String eventId,
    String? eventEmoji,
    String? reason,
  }) async {
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'eventCanceled',
      'p_category': 'notifications',
      'p_priority': 'high',
      'p_deeplink': 'lazzo://events/$eventId',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_event_name': eventName,
      'p_note': reason,
    });
  }

  /// Send group member joined notification (invite accepted)
  /// Triggered when: Someone accepts a group invite
  Future<String?> sendGroupMemberJoined({
    required String recipientUserId,
    required String joinerName,
    required String groupName,
    required String groupId,
  }) async {
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'groupInviteAccepted',
      'p_category': 'notifications',
      'p_priority': 'low',
      'p_deeplink': 'lazzo://groups/$groupId',
      'p_group_id': groupId,
      'p_user_name': joinerName,
      'p_group_name': groupName,
    });
  }

  /// Send location suggestion added notification
  /// Triggered when: Someone suggests a location for an event
  Future<String?> sendLocationSuggestionAdded({
    required String recipientUserId,
    required String suggestorName,
    required String eventName,
    required String eventId,
    required String locationName,
    String? eventEmoji,
  }) async {
    return await _client.rpc('create_notification_secure', params: {
      'p_recipient_user_id': recipientUserId,
      'p_type': 'suggestionAdded',
      'p_category': 'notifications',
      'p_priority': 'low',
      'p_deeplink': 'lazzo://events/$eventId/planning',
      'p_event_id': eventId,
      'p_event_emoji': eventEmoji,
      'p_user_name': suggestorName,
      'p_event_name': eventName,
      'p_place': locationName,
    });
  }
}
