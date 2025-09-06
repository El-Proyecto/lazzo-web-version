import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/app.dart';

import '../features/home/data/data_sources/memory_remote_data_source.dart';
import '../features/home/data/repositories/memory_repository_impl.dart';
import '../features/home/presentation/providers/memory_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // se no futuro precisares iniciar Supabase, Firebase, etc. fazes aqui
  await Supabase.initialize(
    url:
      "https://pgpryaelqhspwhplttzb.supabase.co",
    anonKey:
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBncHJ5YWVscWhzcHdocGx0dHpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzNjY0MzUsImV4cCI6MjA2ODk0MjQzNX0.hPcn2J8zSKTC_rY8OeCmhLdJLhZEMT-yV1EZjYGFD2A");

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
