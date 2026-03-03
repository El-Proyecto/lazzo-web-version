import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for controlling which tab is selected in MainLayout
/// 0 = Home, 1 = Inbox, 2 = Profile (LAZZO 2.0: Groups removed)
final mainLayoutTabProvider = StateProvider<int>((ref) => 0);

/// Provider for controlling which tab is selected in InboxPage
/// 0 = Notifications, 1 = Actions, 2 = Payments
final inboxTabIndexProvider = StateProvider<int?>((ref) => null);

/// Provider for triggering scroll-to-top when tapping active NavBar tab
/// Increment this value to trigger a scroll-to-top action on active page
final scrollToTopProvider = StateProvider<int>((ref) => 0);

/// Provider that checks for a pending (unseen) memoryReady notification.
/// Returns the event_id of the first unseen memoryReady notification, or null.
/// This is used by MainLayout to show the memory ready page on app open.
final pendingMemoryReadyProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  try {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    // Query for unread memoryReady notifications (push category - from DB trigger)
    final response = await client
        .from('notifications')
        .select('id, event_id')
        .eq('recipient_user_id', userId)
        .eq('type', 'memoryReady')
        .eq('is_read', false)
        .order('created_at', ascending: false)
        .limit(1);

    if (response.isEmpty) return null;

    final notification = response.first;
    final eventId = notification['event_id'] as String?;
    final notificationId = notification['id'] as String?;

    if (eventId == null || notificationId == null) return null;

    // Mark it as read immediately so it only shows once
    await client
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);

    return eventId;
  } catch (e) {
    return null;
  }
});
