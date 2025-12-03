import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';

/// Fake implementation of SettingsRepository for development
class FakeSettingsRepository implements SettingsRepository {
  SettingsEntity _settings = const SettingsEntity(
    notificationsEnabled: true,
    language: 'en',
    earlyAccessInvites: 5,
  );

  @override
  Future<SettingsEntity> getSettings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _settings;
  }

  @override
  Future<void> updateNotifications(bool enabled) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _settings = _settings.copyWith(notificationsEnabled: enabled);
  }

  @override
  Future<void> updateLanguage(String language) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _settings = _settings.copyWith(language: language);
  }

  @override
  Future<void> shareInvite() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_settings.earlyAccessInvites > 0) {
      _settings = _settings.copyWith(
        earlyAccessInvites: _settings.earlyAccessInvites - 1,
      );
    }
  }

  @override
  Future<void> logOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // P2: Implement actual logout logic
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // P2: Implement actual account deletion
  }
}
