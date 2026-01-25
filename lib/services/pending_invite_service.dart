import 'package:shared_preferences/shared_preferences.dart';

/// Service to persist pending invite tokens across app restarts
/// Used when a user receives an invite link but needs to signup/login first
class PendingInviteService {
  static const String _pendingInviteTokenKey = 'pending_invite_token';

  /// Save a pending invite token to be processed after login
  static Future<void> savePendingToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingInviteTokenKey, token);
  }

  /// Get the pending invite token (if any)
  static Future<String?> getPendingToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingInviteTokenKey);
  }

  /// Clear the pending invite token after processing
  static Future<void> clearPendingToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingInviteTokenKey);
  }

  /// Check if there's a pending invite token
  static Future<bool> hasPendingToken() async {
    final token = await getPendingToken();
    return token != null && token.isNotEmpty;
  }
}
