import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../data_sources/settings_remote_data_source.dart';
import '../models/settings_model.dart';

/// Repository implementation for settings with Supabase
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource _remoteDataSource;

  SettingsRepositoryImpl(this._remoteDataSource);

  @override
  Future<SettingsEntity> getSettings() async {
    try {
      print('📦 [SettingsRepository] Fetching settings...');

      final json = await _remoteDataSource.getSettings();
      final model = SettingsModel.fromJson(json);
      final entity = model.toEntity();

      print(
          '✅ [SettingsRepository] Settings fetched: notif=${entity.notificationsEnabled}, lang=${entity.language}, invites=${entity.earlyAccessInvites}');

      return entity;
    } catch (e) {
      print('❌ [SettingsRepository] Failed to get settings: $e');
      throw Exception('Failed to get settings: $e');
    }
  }

  @override
  Future<void> updateNotifications(bool enabled) async {
    try {
      print('🔔 [SettingsRepository] Updating notifications to: $enabled');
      await _remoteDataSource.updateNotifications(enabled);
      print('✅ [SettingsRepository] Notifications updated successfully');
    } catch (e) {
      print('❌ [SettingsRepository] Failed to update notifications: $e');
      throw Exception('Failed to update notifications: $e');
    }
  }

  @override
  Future<void> updateLanguage(String language) async {
    try {
      print('🌐 [SettingsRepository] Updating language to: $language');
      await _remoteDataSource.updateLanguage(language);
      print('✅ [SettingsRepository] Language updated successfully');
    } catch (e) {
      print('❌ [SettingsRepository] Failed to update language: $e');
      throw Exception('Failed to update language: $e');
    }
  }

  @override
  Future<void> shareInvite() async {
    try {
      print('🎁 [SettingsRepository] Sharing invite...');
      await _remoteDataSource.shareInvite();
      print('✅ [SettingsRepository] Invite shared successfully');
    } catch (e) {
      print('❌ [SettingsRepository] Failed to share invite: $e');
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
