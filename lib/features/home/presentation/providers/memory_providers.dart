// DI + estado Async

// providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/memory_summary.dart';
import '../../domain/repositories/memory_repository.dart';
import '../../domain/usecases/get_last_memory.dart';
import '../../data/fakes/fake_memory_repository.dart';

// Repo abstrato (por defeito: Fake)
final memoryRepositoryProvider =
    Provider<MemoryRepository>((_) => FakeMemoryRepository());

// Use case injeta o repo
final getLastMemoryProvider =
    Provider<GetLastMemory>((ref) => GetLastMemory(ref.watch(memoryRepositoryProvider)));

// User ID atual (null se não autenticado)

final currentUserIdProvider = Provider<String?>(
  (_) => Supabase.instance.client.auth.currentUser?.id,
);


// Controller: lê userId e chama o use case
final lastMemoryControllerProvider =
    FutureProvider.autoDispose<MemorySummary?>((ref) async {  // REMOVER: trocar por 'fakeid'
  final uid = ref.watch(currentUserIdProvider) ?? '7ccd4b2d-778e-44bf-b119-d72f76529e1e';
  final getLast = ref.watch(getLastMemoryProvider);
  final result = await getLast(uid);
  return result;
});
