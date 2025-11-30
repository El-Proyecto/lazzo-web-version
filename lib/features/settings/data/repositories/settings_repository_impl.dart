import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../data_sources/settings_remote_data_source.dart';

/// Repository implementation for settings with Supabase
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource _remoteDataSource;

  SettingsRepositoryImpl(this._remoteDataSource);

  @override
  Future<SettingsEntity> getSettings() async {
    try {
      // Validate user is authenticated
      await _remoteDataSource.getSettings();

      // For now, return default settings since we don't have preferences table yet
      // TODO P2: Get from user_preferences table when available
      return const SettingsEntity(
        notificationsEnabled: true,
        language: 'en',
        earlyAccessInvites: 3,
      );
    } catch (e) {
      throw Exception('Failed to get settings: $e');
    }
  }

  @override
  Future<void> updateNotifications(bool enabled) async {
    try {
      await _remoteDataSource.updateNotifications(enabled);
    } catch (e) {
      throw Exception('Failed to update notifications: $e');
    }
  }

  @override
  Future<void> updateLanguage(String language) async {
    try {
      await _remoteDataSource.updateLanguage(language);
    } catch (e) {
      throw Exception('Failed to update language: $e');
    }
  }

  @override
  Future<void> shareInvite() async {
    try {
      await _remoteDataSource.shareInvite();
    } catch (e) {
      throw Exception('Failed to share invite: $e');
    }
  }

  @override
  Future<void> logOut() async {
    try {
      await _remoteDataSource.logOut();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}
