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

// AUTH - TODO: Add real implementation imports when available

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

        // Auth repo -> TODO: Refactor auth providers to use DI pattern (from PR 2)
        // authRepositoryProvider.overrideWith(...),
      ],
      child: const LazzoApp(),
    ),
  );
}
