import '../entities/settings_entity.dart';

/// Repository interface for settings operations
abstract class SettingsRepository {
  /// Get current user settings
  Future<SettingsEntity> getSettings();

  /// Update notifications enabled status
  Future<void> updateNotifications(bool enabled);

  /// Update language preference
  Future<void> updateLanguage(String language);

  /// Share early access invite
  Future<void> shareInvite();

  /// Log out current user
  Future<void> logOut();

  /// Delete current user account
  Future<void> deleteAccount();
}
