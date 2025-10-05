import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_current_user_profile.dart';
import '../../domain/usecases/get_profile_by_id.dart';
import '../../domain/usecases/get_user_memories.dart';
import '../../data/fakes/fake_profile_repository.dart';

/// Provider for profile repository - defaults to fake implementation
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => FakeProfileRepository(),
);

/// Provider for GetCurrentUserProfile use case
final getCurrentUserProfileProvider = Provider.autoDispose(
  (ref) => GetCurrentUserProfile(ref.read(profileRepositoryProvider)),
);

/// Provider for GetProfileById use case
final getProfileByIdProvider = Provider.autoDispose(
  (ref) => GetProfileById(ref.read(profileRepositoryProvider)),
);

/// Provider for GetUserMemories use case
final getUserMemoriesProvider = Provider.autoDispose(
  (ref) => GetUserMemories(ref.read(profileRepositoryProvider)),
);

/// Provider for current user profile - exposes AsyncValue for UI consumption
final currentUserProfileProvider = FutureProvider.autoDispose<ProfileEntity>((
  ref,
) async {
  final useCase = ref.read(getCurrentUserProfileProvider);
  return await useCase.call();
});

/// Provider for profile by ID - takes userId parameter
final profileByIdProvider = FutureProvider.autoDispose
    .family<ProfileEntity, String>((ref, userId) async {
      final useCase = ref.read(getProfileByIdProvider);
      return await useCase.call(userId);
    });

/// Provider for user memories - takes userId parameter
final userMemoriesProvider = FutureProvider.family<List<MemoryEntity>, String>((
  ref,
  userId,
) async {
  final useCase = ref.read(getUserMemoriesProvider);
  return await useCase.call(userId);
});
