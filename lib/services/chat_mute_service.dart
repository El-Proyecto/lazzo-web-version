import 'package:shared_preferences/shared_preferences.dart';

/// Service to persist chat mute settings locally
/// Since there's no database table for per-event chat mute settings,
/// this uses SharedPreferences to persist user's mute preferences
class ChatMuteService {
  static const String _keyPrefix = 'chat_mute_';

  /// Check if notifications are muted for a specific event
  static Future<bool> isMuted(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_keyPrefix$eventId') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Set mute status for a specific event
  static Future<void> setMuted(String eventId, bool isMuted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isMuted) {
        await prefs.setBool('$_keyPrefix$eventId', true);
      } else {
        // Remove the key when unmuted to save storage
        await prefs.remove('$_keyPrefix$eventId');
      }
    } catch (e) {
      // Silently fail - non-critical
    }
  }

  /// Toggle mute status for a specific event
  /// Returns the new mute status
  static Future<bool> toggleMuted(String eventId) async {
    final currentStatus = await isMuted(eventId);
    final newStatus = !currentStatus;
    await setMuted(eventId, newStatus);
    return newStatus;
  }
}
