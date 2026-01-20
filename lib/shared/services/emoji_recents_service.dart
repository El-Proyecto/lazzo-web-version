import 'package:shared_preferences/shared_preferences.dart';
import '../constants/event_emojis.dart';

/// Service to manage recently used emojis
/// Tracks user's emoji selection history with a maximum of 8 recents
class EmojiRecentsService {
  static const String _recentsKey = 'emoji_recents';
  static const int _maxRecents = 8;

  /// Get list of recently used emojis (up to 8)
  /// Returns defaults if no recents are stored
  Future<List<String>> getRecents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recents = prefs.getStringList(_recentsKey);
      
      if (recents == null || recents.isEmpty) {
        // Return first 8 defaults if no recents exist
        return EventEmojis.defaults.take(_maxRecents).toList();
      }
      
      return recents;
    } catch (e) {
      // Return defaults on error
      return EventEmojis.defaults.take(_maxRecents).toList();
    }
  }

  /// Add an emoji to recents
  /// - Moves existing emoji to front if already in list
  /// - Adds new emoji to front if not in list
  /// - Maintains maximum of 8 recents
  Future<void> addRecent(String emoji) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recents = prefs.getStringList(_recentsKey) ?? [];

      // Remove emoji if it already exists (to move it to front)
      recents.remove(emoji);

      // Add emoji to the front
      recents.insert(0, emoji);

      // Keep only the most recent 8
      if (recents.length > _maxRecents) {
        recents.removeRange(_maxRecents, recents.length);
      }

      // Save to storage
      await prefs.setStringList(_recentsKey, recents);
    } catch (e) {
      // Silently fail - recents are not critical
    }
  }

  /// Clear all recent emojis
  Future<void> clearRecents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentsKey);
    } catch (e) {
      // Silently fail
    }
  }

  /// Check if an emoji is in recents
  Future<bool> isInRecents(String emoji) async {
    final recents = await getRecents();
    return recents.contains(emoji);
  }
}
