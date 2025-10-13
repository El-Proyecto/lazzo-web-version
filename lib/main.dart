import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'env.dart';

import 'package:app/app.dart';

// MEMORY
import '../features/home/data/data_sources/memory_remote_data_source.dart';
import '../features/home/data/repositories/memory_repository_impl.dart';
import '../features/home/presentation/providers/memory_providers.dart';

// PENDING EVENTS
import '../features/home/data/data_sources/pending_event_remote_data_source.dart';
import '../features/home/data/repositories/pending_event_repository_impl.dart';
import '../features/home/presentation/providers/pending_event_providers.dart';

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

// GROUPS - TODO: Add real implementation imports when available
// import '../features/groups/presentation/providers/groups_provider.dart';

// PROFILE - Real implementation
import '../features/profile/data/data_sources/profile_remote_data_source.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/presentation/providers/profile_providers.dart';

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

        // PendingEvent repo -> real (Supabase)
        pendingEventRepositoryProvider.overrideWith(
          (ref) => PendingEventRepositoryImpl(
            PendingEventRemoteDataSource(Supabase.instance.client),
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

        // Groups repo -> TODO: Add when GroupRepositoryImpl exists
        // groupRepositoryProvider.overrideWith(
        //   (ref) => GroupRepositoryImpl(GroupRemoteDataSource(Supabase.instance.client)),
        // ),

        // ✅ GROUPS repo -> real (Supabase) via DI (P2 implementation)
        groupRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          final dataSource = SupabaseGroupsDataSource(client);
          return GroupRepositoryImpl(dataSource, client);
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

        // EVENT FEATURES -> fake-only (P1 implementation)
        // Both create_event and event features use fake repositories for P1
        // No Supabase integration needed yet
      ],
      child: const LazzoApp(),
    ),
  );
}
