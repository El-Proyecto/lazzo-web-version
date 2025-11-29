import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'env.dart';

import 'package:app/app.dart';

// MEMORY (Home recent memories - different from manage_memory)
import '../features/home/data/data_sources/memory_remote_data_source.dart';
import '../features/home/data/repositories/memory_repository_impl.dart';
import '../features/home/presentation/providers/memory_providers.dart';

// MEMORY MANAGEMENT (upload & manage photos)
import '../features/memory/presentation/providers/memory_providers.dart' as memory_manage;
import '../features/memory/data/data_sources/memory_data_source.dart' as memory_ds;
import '../features/memory/data/data_sources/memory_photo_data_source.dart';
import '../features/memory/data/repositories/memory_repository_impl.dart' as memory_repo;
import '../services/storage_service.dart';

// HOME EVENTS
import 'features/home/data/data_sources/home_event_remote_data_source.dart';
import 'features/home/data/repositories/home_event_repository_impl.dart';
import 'features/home/presentation/providers/home_event_providers.dart'; 

// INBOX PAYMENTS - TODO: Add real implementation imports when available
// import '../features/inbox/data/data_sources/payment_remote_data_source.dart';
// import '../features/inbox/data/repositories/payment_repository_impl.dart';
// import '../features/inbox/presentation/providers/payments_provider.dart';

// INBOX NOTIFICATIONS - TODO: Add real implementation imports when available
// import '../features/inbox/data/data_sources/notification_remote_data_source.dart';
// import '../features/inbox/data/repositories/notification_repository_impl.dart';
// import '../features/inbox/presentation/providers/notifications_provider.dart';

// INBOX ACTIONS - TODO: Add real implementation imports when available
// import '../features/inbox/data/data_sources/action_remote_data_source.dart';
// import '../features/inbox/data/repositories/action_repository_impl.dart';
// import '../features/inbox/presentation/providers/actions_provider.dart';

// GROUPS - Real implementation (commented out for testing fake repository)
import '../features/groups/presentation/providers/groups_provider.dart';
import '../features/groups/data/data_sources/groups_data_source.dart';
import '../features/groups/data/repositories/group_repository_impl.dart';

// GROUP HUB - Real implementation
import '../features/group_hub/presentation/providers/group_hub_providers.dart' as group_hub;
import '../features/group_hub/data/data_sources/group_event_data_source.dart' as group_hub_ds;
import '../features/group_hub/data/repositories/group_event_repository_impl.dart' as group_hub_repo;
import '../features/group_hub/data/data_sources/group_memory_data_source.dart';
import '../features/group_hub/data/repositories/group_memory_repository_impl.dart';
import '../features/group_hub/data/data_sources/group_photos_data_source.dart';
import '../features/group_hub/data/repositories/group_photos_repository_impl.dart';

// PROFILE - Real implementation
import '../features/profile/data/data_sources/profile_remote_data_source.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/presentation/providers/profile_providers.dart';

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
import '../features/event/data/data_sources/chat_remote_data_source.dart';
import '../features/event/data/repositories/event_repository_impl.dart';
import '../features/event/data/repositories/rsvp_repository_impl.dart';
import '../features/event/data/repositories/suggestion_repository_impl.dart';
import '../features/event/data/repositories/poll_repository_impl.dart';
import '../features/event/data/repositories/chat_repository_impl.dart';

// AUTH (DI via providers)
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';

// USERS (para finish_setup)
import '../features/auth/presentation/providers/users_repository_provider.dart';
import '../features/auth/data/datasources/users_remote_datasource.dart';
import '../features/auth/data/repositories/users_repository.dart';

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

        // Payment repo -> TODO: Add when PaymentRepositoryImpl exists
        // paymentRepositoryProvider.overrideWith(
        //   (ref) => PaymentRepositoryImpl(
        //     PaymentRemoteDataSource(Supabase.instance.client),
        //   ),
        // ),

        // Notification repo -> TODO: Add when NotificationRepositoryImpl exists
        // notificationRepositoryProvider.overrideWith(
        //   (ref) => NotificationRepositoryImpl(
        //     NotificationRemoteDataSource(Supabase.instance.client),
        //   ),
        // ),

        // Action repo -> TODO: Add when ActionRepositoryImpl exists
        // actionRepositoryProvider.overrideWith(
        //   (ref) => ActionRepositoryImpl(
        //     ActionRemoteDataSource(Supabase.instance.client),
        //   ),
        // ),

        // ✅ GROUPS repo -> real (Supabase) via DI (P2 implementation)
        groupRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          final dataSource = SupabaseGroupsDataSource(client);
          return GroupRepositoryImpl(dataSource, client);
        }),

        // ✅ GROUP HUB EVENTS repo -> real (Supabase) via DI (Nov 18, 2025)
        group_hub.groupEventRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          final dataSource = group_hub_ds.SupabaseGroupEventDataSource(client);
          return group_hub_repo.GroupEventRepositoryImpl(dataSource);
        }),

        // ✅ GROUP MEMORIES repo -> real (Supabase) via DI (Nov 25, 2025)
        // Updated Nov 27: Added StorageService for signed URL generation
        group_hub.groupMemoryRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          final dataSource = SupabaseGroupMemoryDataSource(client);
          final storageService = StorageService(client);
          return GroupMemoryRepositoryImpl(dataSource, storageService);
        }),

        // ✅ GROUP PHOTOS repo -> real (Supabase) via DI (Nov 25, 2025)
        group_hub.groupPhotosRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          final dataSource = GroupPhotosDataSource(client);
          return GroupPhotosRepositoryImpl(dataSource);
        }),

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

        // Profile repo -> real (Supabase)
        profileRepositoryProvider.overrideWith(
          (ref) => ProfileRepositoryImpl(
            ProfileRemoteDataSource(Supabase.instance.client),
          ),
        ),

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
        chatRepositoryProvider.overrideWith(
          (ref) => ChatRepositoryImpl(
           ChatRemoteDataSource(Supabase.instance.client),
          ),
        ),
      ],
      child: const LazzoApp(),
    ),
  );
}
