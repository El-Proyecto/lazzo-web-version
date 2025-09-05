// DI + estado Async

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/memory_summary.dart';
import '../../domain/repositories/memory_repository.dart';
import '../../domain/usecases/get_last_memory.dart';
import '../../data/fakes/fake_memory_repository.dart';

// DI: por defeito usa Fake; o colega vai dar override na main para Supabase
final memoryRepositoryProvider = Provider<MemoryRepository>((_) => FakeMemoryRepository());
final getLastMemoryProvider = Provider<GetLastMemory>((ref) => GetLastMemory(ref.watch(memoryRepositoryProvider)));

final lastMemoryControllerProvider = AutoDisposeFutureProvider<MemorySummary?>((ref) async {
  // TODO: trocar pelo ID real do utilizador autenticado quando ligares à Auth
  const userId = 'user_dev';
  return ref.watch(getLastMemoryProvider)(userId);
});
