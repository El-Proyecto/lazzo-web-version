import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for settings operations with Supabase
class SettingsRemoteDataSource {
  final SupabaseClient _client;

  SettingsRemoteDataSource(this._client);

  /// Get current user settings from Supabase
  /// Returns user preferences from user_settings table
  /// Creates default settings if they don't exist (for existing users)
  Future<Map<String, dynamic>> getSettings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    
    try {
      // Try to get existing settings
      final response = await _client
          .from('user_settings')
          .select(
              'user_id, notifications_enabled, language, early_access_invites')
          .eq('user_id', userId)
          .maybeSingle(); // Use maybeSingle() instead of single() to handle 0 rows

      if (response != null) {
                return response;
      }

      // Settings don't exist, create default ones
      
      final newSettings = await _client
          .from('user_settings')
          .insert({
            'user_id': userId,
            'notifications_enabled': true,
            'language': 'en',
            'early_access_invites': 3,
          })
          .select(
              'user_id, notifications_enabled, language, early_access_invites')
          .single();

            return newSettings;
    } catch (e) {
            rethrow;
    }
  }

  /// Update notification preferences in Supabase
  Future<void> updateNotifications(bool enabled) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client
        .from('user_settings')
        .update({'notifications_enabled': enabled}).eq('user_id', userId);
  }

  /// Update language preference in Supabase
  Future<void> updateLanguage(String language) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client
        .from('user_settings')
        .update({'language': language}).eq('user_id', userId);
  }

  /// Share early access invite (decrement counter)
  Future<void> shareInvite() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get current invite count
    final current = await _client
        .from('user_settings')
        .select('early_access_invites')
        .eq('user_id', userId)
        .single();

    final currentCount = current['early_access_invites'] as int;

    if (currentCount <= 0) {
      throw Exception('No invites remaining');
    }

    // Decrement invite count
    await _client.from('user_settings').update(
        {'early_access_invites': currentCount - 1}).eq('user_id', userId);
  }

  /// Log out current user from Supabase
  Future<void> logOut() async {
    await _client.auth.signOut();
  }

  /// Delete current user account from Supabase
  /// This will cascade delete all user data according to DB constraints
  Future<void> deleteAccount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Delete user from users table (cascades to related data)
    await _client.from('users').delete().eq('id', userId);

    // Sign out after deletion
    await _client.auth.signOut();
  }
}
