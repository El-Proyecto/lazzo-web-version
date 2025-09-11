// providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/memory_summary.dart';
import '../../domain/repositories/memory_repository.dart';
import '../../domain/usecases/get_last_memory.dart';
import '../../data/fakes/fake_memory_repository.dart';

// Repositório abstrato (por defeito: Fake)
final memoryRepositoryProvider =
    Provider<MemoryRepository>((_) => FakeMemoryRepository());

// Use case que injeta o repo
final getLastMemoryProvider = Provider<GetLastMemory>(
  (ref) => GetLastMemory(ref.watch(memoryRepositoryProvider)),
);

// User ID atual (fallback para um ID fake em DEV se não autenticado)
final currentUserIdProvider = Provider<String>(
  (ref) => Supabase.instance.client.auth.currentUser?.id
      ?? '1d473830-e62a-4aaf-a744-9b22343bfd1d',
);

// Controlador que devolve o último memory
final lastMemoryControllerProvider =
    FutureProvider.autoDispose<MemorySummary?>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  final getLast = ref.watch(getLastMemoryProvider);
  return getLast(uid);
});

