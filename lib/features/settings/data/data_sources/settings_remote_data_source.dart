import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for settings operations with Supabase
class SettingsRemoteDataSource {
  final SupabaseClient _client;

  SettingsRemoteDataSource(this._client);

  /// Get current user settings from Supabase
  /// Returns user preferences stored in users table
  Future<Map<String, dynamic>> getSettings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get user data from users table
    final response = await _client
        .from('users')
        .select('id, email, name')
        .eq('id', userId)
        .single();

    return response;
  }

  /// Update notification preferences in Supabase
  /// In production, this would update user preferences table
  Future<void> updateNotifications(bool enabled) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // TODO P2: Create user_preferences table for settings
    // For now, just validate the operation
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Update language preference in Supabase
  /// In production, this would update user preferences table
  Future<void> updateLanguage(String language) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // TODO P2: Create user_preferences table for language
    // For now, just validate the operation
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Share early access invite
  /// In production, this would create invite records
  Future<void> shareInvite() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // TODO P2: Implement invite system
    await Future.delayed(const Duration(milliseconds: 300));
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
