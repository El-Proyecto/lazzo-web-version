import '../entities/settings_entity.dart';
import '../repositories/settings_repository.dart';

/// Use case to get user settings
class GetSettings {
  final SettingsRepository repository;

  GetSettings(this.repository);

  Future<SettingsEntity> call() {
    return repository.getSettings();
  }
}
