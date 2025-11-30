import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_notifications.dart';
import '../../data/fakes/fake_settings_repository.dart';

/// Provider for settings repository (fake by default)
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return FakeSettingsRepository();
});

/// Provider for get settings use case
final getSettingsUseCaseProvider = Provider<GetSettings>((ref) {
  return GetSettings(ref.watch(settingsRepositoryProvider));
});

/// Provider for update notifications use case
final updateNotificationsUseCaseProvider = Provider<UpdateNotifications>((ref) {
  return UpdateNotifications(ref.watch(settingsRepositoryProvider));
});

/// Provider for settings data
final settingsProvider = FutureProvider<SettingsEntity>((ref) {
  final getSettings = ref.watch(getSettingsUseCaseProvider);
  return getSettings();
});

/// Provider for settings controller
final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<SettingsEntity>>(
  (ref) => SettingsController(ref),
);

class SettingsController extends StateNotifier<AsyncValue<SettingsEntity>> {
  final Ref ref;

  SettingsController(this.ref) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final getSettings = ref.read(getSettingsUseCaseProvider);
      final settings = await getSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    final updateNotifications = ref.read(updateNotificationsUseCaseProvider);
    try {
      await updateNotifications(enabled);
      await _loadSettings();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateLanguage(String language) async {
    final repository = ref.read(settingsRepositoryProvider);
    try {
      await repository.updateLanguage(language);
      await _loadSettings();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> shareInvite() async {
    final repository = ref.read(settingsRepositoryProvider);
    try {
      await repository.shareInvite();
      await _loadSettings();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> logOut() async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.logOut();
  }

  Future<void> deleteAccount() async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.deleteAccount();
  }
}
