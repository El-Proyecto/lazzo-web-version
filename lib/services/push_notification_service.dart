import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Top-level function for background message handler (required by Firebase)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
      
  // Store deeplink for later navigation when app opens
  final deeplink = message.data['deeplink'];
  if (deeplink != null && deeplink.isNotEmpty) {
    // TODO: Save to local storage using shared_preferences
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
    
        
    // Request permissions (iOS requires this, Android grants by default)
    final settings = await _requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
            return;
    }
    
        
    // Get FCM token and register with Supabase
    await _registerToken();
    
    // Listen for token refresh (happens when app reinstalled, data cleared, etc)
    _messaging.onTokenRefresh.listen((newToken) {
            _saveTokenToSupabase(newToken);
    });
    
    // Handle foreground messages (when app is open)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background/terminated messages when user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
            _handleMessageOpenedApp(initialMessage);
    }
    
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
                return;
      }
      
            await _saveTokenToSupabase(token);
    } catch (e) {
          }
  }

  /// Save/update push token in Supabase
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
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
      
          } catch (e) {
          }
  }

  /// Handle foreground message (app is open)
  void _handleForegroundMessage(RemoteMessage message) {
                    
    // TODO: Show in-app notification banner
    // Could use ScaffoldMessenger or custom overlay
    // For now, just log it
  }

  /// Handle message when user taps notification (app in background/terminated)
  void _handleMessageOpenedApp(RemoteMessage message) {
            
    final deeplink = message.data['deeplink'] as String?;
    final notificationId = message.data['notification_id'] as String?;
    
    if (deeplink != null && deeplink.isNotEmpty) {
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
      
          } catch (e) {
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
      
          } catch (e) {
          }
  }

  /// Delete FCM token (call on logout or account deletion)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
          } catch (e) {
          }
  }
}
