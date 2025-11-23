import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/memory_entity.dart';
import '../../domain/repositories/memory_repository.dart';
import '../../domain/usecases/get_memory.dart';
import '../../domain/usecases/get_memory_photos.dart';
import '../../domain/usecases/share_memory.dart';
import '../../domain/usecases/update_memory_cover.dart';
import '../../domain/usecases/remove_memory_photo.dart';
import '../../data/fakes/fake_memory_repository.dart';

/// Repository provider (fake by default)
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return FakeMemoryRepository();
});

/// Get memory use case provider
final getMemoryUseCaseProvider = Provider<GetMemory>((ref) {
  return GetMemory(ref.watch(memoryRepositoryProvider));
});

/// Share memory use case provider
final shareMemoryUseCaseProvider = Provider<ShareMemory>((ref) {
  return ShareMemory(ref.watch(memoryRepositoryProvider));
});

/// Get memory photos use case provider
final getMemoryPhotosUseCaseProvider = Provider<GetMemoryPhotos>((ref) {
  return GetMemoryPhotos(ref.watch(memoryRepositoryProvider));
});

/// Update memory cover use case provider
final updateMemoryCoverUseCaseProvider = Provider<UpdateMemoryCover>((ref) {
  return UpdateMemoryCover(ref.watch(memoryRepositoryProvider));
});

/// Remove memory photo use case provider
final removeMemoryPhotoUseCaseProvider = Provider<RemoveMemoryPhoto>((ref) {
  return RemoveMemoryPhoto(ref.watch(memoryRepositoryProvider));
});

/// Memory detail provider
final memoryDetailProvider =
    FutureProvider.family<MemoryEntity?, String>((ref, memoryId) async {
  final useCase = ref.watch(getMemoryUseCaseProvider);
  return useCase(memoryId);
});

/// Memory photos provider (ordered for viewer: covers first, then grid)
final memoryPhotosProvider =
    FutureProvider.family<List<MemoryPhoto>, String>((ref, memoryId) async {
  final useCase = ref.watch(getMemoryPhotosUseCaseProvider);
  return useCase(memoryId);
});

/// Share memory action provider
final shareMemoryProvider =
    StateNotifierProvider<ShareMemoryNotifier, AsyncValue<String?>>((ref) {
  return ShareMemoryNotifier(ref.watch(shareMemoryUseCaseProvider));
});

/// State notifier for share action
class ShareMemoryNotifier extends StateNotifier<AsyncValue<String?>> {
  final ShareMemory _shareMemory;

  ShareMemoryNotifier(this._shareMemory) : super(const AsyncValue.data(null));

  Future<void> share(String memoryId) async {
    state = const AsyncValue.loading();
    try {
      final shareUrl = await _shareMemory(memoryId);
      state = AsyncValue.data(shareUrl);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
