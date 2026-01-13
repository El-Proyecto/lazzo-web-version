import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;

/// Service for managing APNs push notification tokens
/// Handles registration, updates, and cleanup of device tokens
class PushTokenService {
  final SupabaseClient _client;

  PushTokenService(this._client);

  /// Register or update device push token
  /// Should be called when:
  /// 1. App launches and token is available
  /// 2. Token is refreshed by the system
  /// 3. User logs in
  Future<void> registerPushToken({
    required String deviceToken,
    String? deviceName,
    String? appVersion,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint(
            '[PushToken] User not authenticated, skipping token registration');
        return;
      }

      // Detect platform
      final platform = Platform.isIOS ? 'ios' : 'android';

      // Detect environment (production vs sandbox)
      // In Flutter: kReleaseMode = production (TestFlight/App Store)
      // In Flutter: kDebugMode/kProfileMode = sandbox (Xcode debug)
      final environment = kReleaseMode ? 'production' : 'sandbox';

      debugPrint('[PushToken] Registering token for user $userId');
      debugPrint('[PushToken] Platform: $platform, Environment: $environment');

      // Upsert token (insert or update if exists)
      await _client.from('user_push_tokens').upsert({
        'user_id': userId,
        'device_token': deviceToken,
        'platform': platform,
        'environment': environment,
        'device_name': deviceName,
        'app_version': appVersion,
        'is_active': true,
        'last_used_at': DateTime.now().toIso8601String(),
      }, onConflict: 'device_token,platform');

      debugPrint('[PushToken] Token registered successfully');
    } catch (e) {
      debugPrint('[PushToken] Error registering token: $e');
      // Don't rethrow - token registration should never crash the app
    }
  }

  /// Mark current device token as inactive (user logged out or disabled notifications)
  Future<void> deactivateCurrentToken(String deviceToken) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('user_push_tokens')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('user_id', userId)
          .eq('device_token', deviceToken);

      debugPrint('[PushToken] Token deactivated');
    } catch (e) {
      debugPrint('[PushToken] Error deactivating token: $e');
    }
  }

  /// Delete all tokens for current user (complete cleanup on logout)
  Future<void> deleteAllUserTokens() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('user_push_tokens').delete().eq('user_id', userId);

      debugPrint('[PushToken] All tokens deleted for user');
    } catch (e) {
      debugPrint('[PushToken] Error deleting tokens: $e');
    }
  }

  /// Get all active tokens for current user (for debugging)
  Future<List<Map<String, dynamic>>> getActiveTokens() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('user_push_tokens')
          .select(
              'device_token, platform, environment, device_name, last_used_at')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[PushToken] Error fetching tokens: $e');
      return [];
    }
  }
}
