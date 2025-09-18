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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização do Supabase
  print('[MAIN] Iniciando Supabase com URL: ${Env.supabaseUrl}');
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // garante fluxo mobile correto
      ),
    );

    print('[MAIN] Supabase inicializado com sucesso');
    print('[MAIN] Cliente Supabase: ${Supabase.instance.client.auth.currentSession}');
  } catch (e) {
    print('[MAIN] Erro ao inicializar Supabase: $e');
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
      ],
      child: const LazzoApp(),
    ),
  );
}
