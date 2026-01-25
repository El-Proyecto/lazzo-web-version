import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_notifications.dart';
import '../../data/fakes/fake_settings_repository.dart';

// Import providers to invalidate on logout
import '../../../home/presentation/providers/home_event_providers.dart';
//import '../../../home/presentation/providers/memory_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../inbox/presentation/providers/notifications_provider.dart';
import '../../../inbox/presentation/providers/payments_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    final updateNotifications = ref.read(updateNotificationsUseCaseProvider);
    try {
      await updateNotifications(enabled);
      // Update state directly without loading to prevent page reset
      state.whenData((settings) {
        state = AsyncValue.data(
          SettingsEntity(
            notificationsEnabled: enabled,
            language: settings.language,
            earlyAccessInvites: settings.earlyAccessInvites,
          ),
        );
      });
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
    
    // CRITICAL: Invalidate all user-specific providers to clear cached data
    // This prevents stale data from showing when logging in with a different account
    _invalidateAllUserProviders();
  }

  /// Invalidate all providers that cache user-specific data
  void _invalidateAllUserProviders() {
    // Home providers
    ref.invalidate(nextEventControllerProvider);
    ref.invalidate(confirmedEventsControllerProvider);
    ref.invalidate(homeEventsControllerProvider);
    ref.invalidate(livingAndRecapEventsControllerProvider);
    ref.invalidate(recentMemoriesControllerProvider);
    ref.invalidate(paymentSummariesControllerProvider);
    
    // Profile providers
    ref.invalidate(currentUserProfileProvider);
    
    // Groups providers
    ref.invalidate(groupsProvider);
    
    // Inbox providers
    ref.invalidate(notificationsProvider);
    ref.invalidate(paymentsOwedToUserProvider);
    ref.invalidate(paymentsUserOwesProvider);
    
    // Auth provider
    ref.invalidate(authProvider);
  }

  Future<void> deleteAccount() async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.deleteAccount();
  }
}
