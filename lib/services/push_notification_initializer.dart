import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'push_notification_manager.dart';

/// Provider that listens to auth state and initializes push notifications on login
final pushNotificationInitializerProvider = Provider<void>((ref) {
  final client = Supabase.instance.client;
  final pushManager = ref.watch(pushNotificationManagerProvider);

  // Listen to auth state changes
  client.auth.onAuthStateChange.listen((data) {
    final session = data.session;

    if (session != null) {
      // User logged in - initialize push notifications
            pushManager.initialize();
    } else {
      // User logged out - cleanup handled by PushTokenService if needed
          }
  });

  // Also initialize immediately if user is already logged in
  if (client.auth.currentUser != null) {
        pushManager.initialize();
  }
});
