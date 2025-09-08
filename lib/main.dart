import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // importa o riverpod
import 'env.dart';



import 'package:app/app.dart';

import '../features/home/data/data_sources/memory_remote_data_source.dart';
import '../features/home/data/repositories/memory_repository_impl.dart';
import '../features/home/presentation/providers/memory_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(Env.supabaseUrl.isNotEmpty, 'SUPABASE_URL está vazio');
  assert(Env.supabaseAnonKey.isNotEmpty, 'SUPABASE_ANON_KEY está vazio');
  // se no futuro precisares iniciar Supabase, Firebase, etc. fazes aqui
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey:  Env.supabaseAnonKey,
    );
  runApp(
  ProviderScope(
    overrides: [
      memoryRepositoryProvider.overrideWith(
        (ref) => MemoryRepositoryImpl(
          MemoryRemoteDataSource(Supabase.instance.client),
        ),
      ),
    ],
    child: LazzoApp(),
  ),
);
}
