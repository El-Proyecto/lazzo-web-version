import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for controlling which tab is selected in MainLayout
/// 0 = Home, 1 = Inbox, 2 = Profile (LAZZO 2.0: Groups removed)
final mainLayoutTabProvider = StateProvider<int>((ref) => 0);

/// Provider for controlling which tab is selected in InboxPage
/// 0 = Notifications, 1 = Actions, 2 = Payments
final inboxTabIndexProvider = StateProvider<int?>((ref) => null);

/// Provider for triggering scroll-to-top when tapping active NavBar tab
/// Increment this value to trigger a scroll-to-top action on active page
final scrollToTopProvider = StateProvider<int>((ref) => 0);
