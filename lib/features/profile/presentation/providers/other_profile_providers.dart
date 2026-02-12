import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/other_profile_entity.dart';
import '../../domain/repositories/other_profile_repository.dart';
import '../../domain/usecases/get_other_user_profile.dart';
import '../../data/fakes/fake_other_profile_repository.dart';

/// Provider for the other profile repository (fake by default)
final otherProfileRepositoryProvider = Provider<OtherProfileRepository>((ref) {
  return FakeOtherProfileRepository();
});

/// Provider for getting another user's profile
final otherUserProfileProvider =
    FutureProvider.family<OtherProfileEntity, String>((ref, userId) async {
  final repository = ref.watch(otherProfileRepositoryProvider);
  final useCase = GetOtherUserProfile(repository);
  return useCase(userId);
});

// LAZZO 2.0: Group invite providers removed (invitableGroupsProvider, inviteToGroupProvider, acceptGroupInviteProvider, declineGroupInviteProvider)
