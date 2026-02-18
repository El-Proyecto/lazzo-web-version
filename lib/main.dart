import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'env.dart';

import 'package:lazzo/app.dart';

// REALTIME (web → app sync via Supabase channels)
import '../services/realtime_service.dart';

// MEMORY (Home recent memories - different from manage_memory)
import '../features/home/data/data_sources/memory_remote_data_source.dart';
import '../features/home/data/repositories/memory_repository_impl.dart';
import '../features/home/presentation/providers/memory_providers.dart';

// MEMORY MANAGEMENT (upload & manage photos)
import '../features/memory/presentation/providers/memory_providers.dart'
    as memory_manage;
import '../features/memory/data/data_sources/memory_data_source.dart'
    as memory_ds;
import '../features/memory/data/data_sources/memory_photo_data_source.dart';
import '../features/memory/data/repositories/memory_repository_impl.dart'
    as memory_repo;
import '../services/storage_service.dart';

// HOME EVENTS
import 'features/home/data/data_sources/home_event_remote_data_source.dart';
import 'features/home/data/repositories/home_event_repository_impl.dart';
import 'features/home/presentation/providers/home_event_providers.dart';

// HOME RECENT MEMORIES - Real implementation
import 'features/home/data/data_sources/recent_memory_data_source.dart';
import 'features/home/data/repositories/recent_memory_repository_impl.dart';

// LAZZO 2.0: Payments removed

// INBOX NOTIFICATIONS - Real implementation (P2)
import 'features/inbox/data/data_sources/notification_remote_data_source.dart';
import 'features/inbox/data/repositories/notification_repository_impl.dart';
import 'features/inbox/presentation/providers/notifications_provider.dart';

// INBOX ACTIONS - Real implementation (computed from event data)
import 'features/inbox/data/data_sources/action_remote_data_source.dart';
import 'features/inbox/data/repositories/action_repository_impl.dart';
import 'features/inbox/presentation/providers/actions_provider.dart';

// LAZZO 2.0: Groups + Expenses removed

// LAZZO 2.0: notification_service import unused
// import 'services/notification_service.dart';

// PROFILE - Real implementation
import '../features/profile/data/data_sources/profile_remote_data_source.dart';
import '../features/profile/data/data_sources/profile_memory_data_source.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/presentation/providers/profile_providers.dart';

// OTHER PROFILE - Real implementation (P2)
import '../features/profile/data/data_sources/other_profile_data_source.dart';
import '../features/profile/data/repositories/other_profile_repository_impl.dart';
import '../features/profile/presentation/providers/other_profile_providers.dart';

// CREATE EVENT - Real implementation
import '../features/create_event/presentation/providers/event_providers.dart'
    as create_event;
import '../features/create_event/data/repositories/event_repository_impl.dart'
    as create_event_impl;

// EVENT FEATURES - Real implementation
import '../features/event/presentation/providers/event_providers.dart';
import '../features/event/data/data_sources/event_remote_data_source.dart';
import '../features/event/data/data_sources/event_photo_data_source.dart';
import '../features/event/data/repositories/event_photo_repository_impl.dart';
import '../features/event/data/data_sources/rsvp_remote_data_source.dart';
import '../features/event/data/data_sources/suggestion_remote_data_source.dart';
import '../features/event/data/data_sources/poll_remote_data_source.dart';
import '../features/event/data/repositories/event_repository_impl.dart';
import '../features/event/data/repositories/rsvp_repository_impl.dart';
import '../features/event/data/repositories/suggestion_repository_impl.dart';
import '../features/event/data/repositories/poll_repository_impl.dart';

// AUTH (DI via providers)
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';

// USERS (para finish_setup)
import '../features/auth/presentation/providers/users_repository_provider.dart';
import '../features/auth/data/datasources/users_remote_datasource.dart';
import '../features/auth/data/repositories/users_repository.dart';

// SETTINGS - Real implementation
import '../features/settings/presentation/providers/settings_providers.dart';
import '../features/settings/data/data_sources/settings_remote_data_source.dart';
import '../features/settings/data/repositories/settings_repository_impl.dart';

// REPORT PROBLEM - Real implementation (P2)
import '../features/settings/presentation/providers/report_providers.dart';
import '../features/settings/data/data_sources/report_remote_data_source.dart';
import '../features/settings/data/repositories/report_repository_impl.dart';

// SETTINGS SUGGESTIONS - Real implementation (P2)
import '../features/settings/presentation/providers/suggestion_providers.dart'
    as settings_suggestion;
import '../features/settings/data/data_sources/suggestion_remote_data_source.dart'
    as settings_suggestion_ds;
import '../features/settings/data/repositories/suggestion_repository_impl.dart'
    as settings_suggestion_repo;

// CREATE EVENT & EVENT FEATURES (P1 - fake only, no imports needed)
// Default fake repositories will be used automatically

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização do Supabase
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // garante fluxo mobile correto
      ),
    );
  } catch (e) {
    rethrow;
  }
  runApp(
    ProviderScope(
      overrides: [
        // ✅ REALTIME SERVICE -> live updates from Supabase (web→app sync)
        realtimeServiceProvider.overrideWith((ref) {
          final service = RealtimeService(Supabase.instance.client);
          service.subscribe();
          ref.onDispose(() => service.dispose());
          return service;
        }),

        // Memory repo -> real (Supabase)
        memoryRepositoryProvider.overrideWith(
          (ref) => MemoryRepositoryImpl(
            MemoryRemoteDataSource(Supabase.instance.client),
          ),
        ),

        // ✅ HOME EVENTS repo -> real (Supabase) - NEW UNIFIED STRUCTURE
        homeEventRepositoryProvider.overrideWith(
          (ref) => HomeEventRepositoryImpl(
            HomeEventRemoteDataSource(Supabase.instance.client),
            ref, // Pass ref to access current user ID
          ),
        ),

        // ✅ HOME RECENT MEMORIES repo -> real (Supabase) - queries events from last 30 days
        recentMemoryRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          // Get user ID from auth state
          final userId = client.auth.currentUser?.id;
          if (userId == null) {
            throw Exception(
                'User must be authenticated to fetch recent memories');
          }
          final dataSource = RecentMemoryDataSource(client);
          final storageService = StorageService(client);
          return RecentMemoryRepositoryImpl(
            dataSource: dataSource,
            storageService: storageService,
            userId: userId,
          );
        }),

        // LAZZO 2.0: Payments DI removed

        // ✅ INBOX NOTIFICATIONS repo -> real (Supabase) via DI (Dec 13, 2025)
        notificationRepositoryProvider.overrideWith(
          (ref) {
            final client = Supabase.instance.client;
            final userId = client.auth.currentUser?.id ?? '';
            final dataSource = NotificationRemoteDataSource(client);
            return NotificationRepositoryImpl(dataSource, userId);
          },
        ),

        // ✅ INBOX ACTIONS repo -> real (computed from Supabase event data)
        actionRepositoryProvider.overrideWith(
          (ref) => ActionRepositoryImpl(
            ActionRemoteDataSource(Supabase.instance.client),
          ),
        ),

        // ✅ MEMORY MANAGEMENT repo -> real (Supabase) via DI (Nov 27, 2025)
        memory_manage.memoryRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          final memoryDataSource = memory_ds.MemoryDataSource(client);
          final photoDataSource = MemoryPhotoDataSource(client);
          final storageService = StorageService(client);
          return memory_repo.MemoryRepositoryImpl(
            memoryDataSource,
            photoDataSource,
            storageService,
          );
        }),

        // ✅ PROFILE repo -> real (Supabase) with memories from events table
        profileRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          final remoteDataSource = ProfileRemoteDataSource(client);
          final memoryDataSource = ProfileMemoryDataSource(client);
          final storageService = StorageService(client);
          return ProfileRepositoryImpl(
            remoteDataSource,
            memoryDataSource,
            storageService,
          );
        }),

        // ✅ OTHER PROFILE repo -> real (Supabase) with shared memories + notifications (P2 Implementation)
        otherProfileRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          final currentUserId = client.auth.currentUser?.id ?? '';
          final dataSource = OtherProfileDataSource(client);
          final storageService = StorageService(client);
          return OtherProfileRepositoryImpl(
            dataSource: dataSource,
            storageService: storageService,
            currentUserId: currentUserId,
          );
        }),

        // authRepositoryProvider.overrideWith(...),
        // ✅ AUTH repo -> real (Supabase) via DI
        authRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          return AuthRepositoryImpl(AuthRemoteDatasource(client));
        }),

        // ✅ USERS repo -> real (Supabase) via DI (usado no finish_setup)
        usersRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          return UsersRepository(UsersRemoteDatasource(client));
        }),

        // ✅ CREATE EVENT repo -> real (Supabase) via DI
        create_event.eventRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          return create_event_impl.EventRepositoryImpl(client);
        }),

        // ✅ EVENT DETAIL FEATURES -> real (Supabase) via DI (P2 implementation)
        eventRepositoryProvider.overrideWith(
          (ref) => EventRepositoryImpl(
            EventRemoteDataSource(Supabase.instance.client),
          ),
        ),
        rsvpRepositoryProvider.overrideWith(
          (ref) => RsvpRepositoryImpl(
            RsvpRemoteDataSource(Supabase.instance.client),
          ),
        ),
        suggestionRepositoryProvider.overrideWith(
          (ref) => SuggestionRepositoryImpl(
            SuggestionRemoteDataSource(Supabase.instance.client),
          ),
        ),
        pollRepositoryProvider.overrideWith(
          (ref) => PollRepositoryImpl(
            PollRemoteDataSource(Supabase.instance.client),
          ),
        ),

        // ✅ EVENT PHOTO UPLOAD -> real (Supabase Storage) via DI (Nov 25, 2025)
        eventPhotoRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          final dataSource = EventPhotoDataSource(client);
          return EventPhotoRepositoryImpl(dataSource);
        }),

        // ✅ SETTINGS repo -> real (Supabase) via DI (P2 Implementation Complete)
        settingsRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          final dataSource = SettingsRemoteDataSource(client);
          return SettingsRepositoryImpl(dataSource);
        }),

        // ✅ REPORT PROBLEM repo -> real (Supabase) via DI (P2 Implementation)
        reportRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          final dataSource = ReportRemoteDataSource(client);
          return ReportRepositoryImpl(dataSource);
        }),

        // ✅ SETTINGS SUGGESTION repo -> real (Supabase) via DI (P2 Implementation)
        settings_suggestion.suggestionRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          final dataSource =
              settings_suggestion_ds.SuggestionRemoteDataSource(client);
          return settings_suggestion_repo.SuggestionRepositoryImpl(dataSource);
        }),
      ],
      child: const LazzoApp(),
    ),
  );
}
