import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Top-level function for background message handler (required by Firebase)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[PushNotifications] 📱 Background message: ${message.messageId}');
  print('[PushNotifications] Data: ${message.data}');
  
  // Store deeplink for later navigation when app opens
  final deeplink = message.data['deeplink'];
  if (deeplink != null && deeplink.isNotEmpty) {
    // TODO: Save to local storage using shared_preferences
    print('[PushNotifications] 🔗 Saving deeplink for later: $deeplink');
  }
}

/// Provider for PushNotificationService
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(
    Supabase.instance.client,
    FirebaseMessaging.instance,
  );
});

/// Service for managing push notifications (FCM/APNs)
/// Responsibilities:
/// - Request notification permissions
/// - Register device token with Supabase
/// - Handle foreground notifications
/// - Handle background/terminated notifications
/// - Navigate to deeplinks
class PushNotificationService {
  final SupabaseClient _supabase;
  final FirebaseMessaging _messaging;
  
  // Callback for deeplink navigation
  Function(String deeplink)? _onDeeplinkReceived;

  PushNotificationService(this._supabase, this._messaging);

  /// Initialize push notification system
  /// Call this in main.dart after Firebase.initializeApp()
  Future<void> initialize({
    Function(String deeplink)? onDeeplinkReceived,
  }) async {
    _onDeeplinkReceived = onDeeplinkReceived;
    
    print('[PushNotifications] 🚀 Initializing...');
    
    // Request permissions (iOS requires this, Android grants by default)
    final settings = await _requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('[PushNotifications] ❌ Permission denied');
      return;
    }
    
    print('[PushNotifications] ✅ Permission granted: ${settings.authorizationStatus}');
    
    // Get FCM token and register with Supabase
    await _registerToken();
    
    // Listen for token refresh (happens when app reinstalled, data cleared, etc)
    _messaging.onTokenRefresh.listen((newToken) {
      print('[PushNotifications] 🔄 Token refreshed: ${newToken.substring(0, 20)}...');
      _saveTokenToSupabase(newToken);
    });
    
    // Handle foreground messages (when app is open)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background/terminated messages when user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('[PushNotifications] 📬 App opened from terminated state');
      _handleMessageOpenedApp(initialMessage);
    }
    
    print('[PushNotifications] ✅ Initialization complete');
  }

  /// Request notification permissions (iOS)
  Future<NotificationSettings> _requestPermission() async {
    return await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  /// Get FCM token and save to Supabase push_tokens table
  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        print('[PushNotifications] ❌ Failed to get FCM token');
        return;
      }
      
      print('[PushNotifications] 📝 Got FCM token: ${token.substring(0, 20)}...');
      await _saveTokenToSupabase(token);
    } catch (e) {
      print('[PushNotifications] ❌ Error registering token: $e');
    }
  }

  /// Save/update push token in Supabase
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('[PushNotifications] ❌ No user logged in, cannot save token');
        return;
      }
      
      // Determine platform
      final platform = defaultTargetPlatform == TargetPlatform.iOS 
          ? 'ios' 
          : defaultTargetPlatform == TargetPlatform.android 
              ? 'android' 
              : 'web';
      
      // Upsert token (insert or update if exists)
      await _supabase.from('push_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': platform,
        'is_active': true,
        'last_used_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,token');
      
      print('[PushNotifications] ✅ Token saved to Supabase for user: $userId');
    } catch (e) {
      print('[PushNotifications] ❌ Error saving token to Supabase: $e');
    }
  }

  /// Handle foreground message (app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    print('[PushNotifications] 📱 Foreground message received');
    print('[PushNotifications] Title: ${message.notification?.title}');
    print('[PushNotifications] Body: ${message.notification?.body}');
    print('[PushNotifications] Data: ${message.data}');
    
    // TODO: Show in-app notification banner
    // Could use ScaffoldMessenger or custom overlay
    // For now, just log it
  }

  /// Handle message when user taps notification (app in background/terminated)
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('[PushNotifications] 👆 User tapped notification');
    print('[PushNotifications] Data: ${message.data}');
    
    final deeplink = message.data['deeplink'] as String?;
    final notificationId = message.data['notification_id'] as String?;
    
    if (deeplink != null && deeplink.isNotEmpty) {
      print('[PushNotifications] 🔗 Navigating to deeplink: $deeplink');
      _onDeeplinkReceived?.call(deeplink);
      
      // Mark notification as read
      if (notificationId != null) {
        _markNotificationAsRead(notificationId);
      }
    }
  }

  /// Mark notification as read in Supabase
  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      
      print('[PushNotifications] ✅ Marked notification as read: $notificationId');
    } catch (e) {
      print('[PushNotifications] ❌ Error marking notification as read: $e');
    }
  }

  /// Unregister token (call on logout)
  Future<void> unregisterToken() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      final token = await _messaging.getToken();
      if (token == null) return;
      
      // Mark token as inactive instead of deleting (for analytics)
      await _supabase
          .from('push_tokens')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('token', token);
      
      print('[PushNotifications] ✅ Token unregistered');
    } catch (e) {
      print('[PushNotifications] ❌ Error unregistering token: $e');
    }
  }

  /// Delete FCM token (call on logout or account deletion)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      print('[PushNotifications] ✅ FCM token deleted');
    } catch (e) {
      print('[PushNotifications] ❌ Error deleting FCM token: $e');
    }
  }
}
