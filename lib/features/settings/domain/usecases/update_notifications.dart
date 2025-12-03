import '../repositories/settings_repository.dart';

/// Use case to update notifications preference
class UpdateNotifications {
  final SettingsRepository repository;

  UpdateNotifications(this.repository);

  Future<void> call(bool enabled) {
    return repository.updateNotifications(enabled);
  }
}
