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

// GROUPS - TODO: Add real implementation imports when available
// import '../features/groups/presentation/providers/groups_provider.dart';

// PROFILE - TODO: Add real implementation imports when available
// import '../features/profile/presentation/providers/profile_providers.dart';

// AUTH (DI via providers)
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';

// USERS (para finish_setup)
import '../features/auth/presentation/providers/users_repository_provider.dart';
import '../features/auth/data/datasources/users_remote_datasource.dart';
import '../features/auth/data/repositories/users_repository.dart';

// CREATE EVENT (P2 implementation)
import 'features/create_event/presentation/providers/event_providers.dart';
import 'features/create_event/data/repositories/event_repository_impl.dart';



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

        // Groups repo -> TODO: Add when GroupRepositoryImpl exists
        // groupRepositoryProvider.overrideWith(
        //   (ref) => GroupRepositoryImpl(GroupRemoteDataSource(Supabase.instance.client)),
        // ),

        // Profile repo -> TODO: Add when ProfileRepositoryImpl exists
        // profileRepositoryProvider.overrideWith(
        //   (ref) => ProfileRepositoryImpl(ProfileRemoteDataSource(Supabase.instance.client)),
        // ),

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

        // ✅ CREATE EVENT repo -> real (Supabase) via DI (P2 implementation)
        eventRepositoryProvider.overrideWith((ref) {
          final client = Supabase.instance.client;
          return EventRepositoryImpl(client);
        }),

      ],
      child: const LazzoApp(),
    ),
  );
}
