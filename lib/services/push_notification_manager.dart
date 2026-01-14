import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lazzo/services/push_token_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;

/// Provider for PushTokenService
final pushTokenServiceProvider = Provider<PushTokenService>((ref) {
  return PushTokenService(Supabase.instance.client);
});

/// Provider for PushNotificationManager
final pushNotificationManagerProvider =
    Provider<PushNotificationManager>((ref) {
  final pushTokenService = ref.watch(pushTokenServiceProvider);
  return PushNotificationManager(pushTokenService);
});

/// Manages push notification setup and token registration
/// Handles communication with native iOS code via MethodChannel
class PushNotificationManager {
  static const MethodChannel _channel =
      MethodChannel('com.lazzo.app/push_notifications');
  final PushTokenService _pushTokenService;

  PushNotificationManager(this._pushTokenService) {
    _setupMethodCallHandler();
  }

  /// Initialize push notifications (call on app launch after authentication)
  Future<void> initialize() async {
    if (!Platform.isIOS) {
      // Android support can be added later
      return;
    }

    // Method call handler is already set up in constructor
    // Native code will automatically request permissions and send token
  }

  /// Setup handler for calls from native iOS code
  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onTokenReceived':
          final token = call.arguments as String;
          await _handleTokenReceived(token);
          break;
        case 'onNotificationTapped':
          final deeplink = call.arguments as String;
          await _handleNotificationTapped(deeplink);
          break;
        default:
          print('[PushNotifications] Unknown method: ${call.method}');
      }
    });
  }

  /// Handle token received from APNs
  Future<void> _handleTokenReceived(String token) async {
    print('[PushNotifications] Token received: ${token.substring(0, 20)}...');

    try {
      // Get device info
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceName = Platform.isIOS ? 'iPhone' : 'Android';
      final appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';

      // Register token with Supabase
      await _pushTokenService.registerPushToken(
        deviceToken: token,
        deviceName: deviceName,
        appVersion: appVersion,
      );
    } catch (e) {
      print('[PushNotifications] Error handling token: $e');
    }
  }

  /// Handle notification tap (deep link navigation)
  Future<void> _handleNotificationTapped(String deeplink) async {
    print('[PushNotifications] Notification tapped: $deeplink');

    try {
      final uri = Uri.parse(deeplink);
      // Parse the deep link and trigger app_links to handle navigation
      // The AppLinks instance in app.dart will process this URI
      // This could navigate to events, groups, inbox, etc.
      // Note: app_links package handles lazzo:// scheme automatically
      print('[PushNotifications] Parsed deeplink: ${uri.toString()}');
    } catch (e) {
      print('[PushNotifications] Error parsing deeplink: $e');
    }
  }

  /// Manually refresh token (useful for debugging or after permission changes)
  Future<void> refreshToken() async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('refreshToken');
    } catch (e) {
      print('[PushNotifications] Error refreshing token: $e');
    }
  }
}
