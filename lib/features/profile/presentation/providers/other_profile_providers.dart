import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/other_profile_entity.dart';
import '../../domain/entities/invite_group_entity.dart';
import '../../domain/repositories/other_profile_repository.dart';
import '../../domain/usecases/get_other_user_profile.dart';
import '../../domain/usecases/get_invitable_groups.dart';
import '../../domain/usecases/invite_to_group.dart';
import '../../data/fakes/fake_other_profile_repository.dart';

/// Provider for the other profile repository (fake by default)
final otherProfileRepositoryProvider = Provider<OtherProfileRepository>((ref) {
  return FakeOtherProfileRepository();
});

/// Provider for getting another user's profile
final otherUserProfileProvider =
    FutureProvider.family<OtherProfileEntity, String>((ref, userId) async {
  print('🟣 [Provider] otherUserProfileProvider created for userId: $userId');
  final repository = ref.watch(otherProfileRepositoryProvider);
  print('🟣 [Provider] Repository type: ${repository.runtimeType}');
  final useCase = GetOtherUserProfile(repository);
  print('🟣 [Provider] Calling use case...');
  return useCase(userId);
});

/// Provider for getting invitable groups
final invitableGroupsProvider =
    FutureProvider.family<List<InviteGroupEntity>, String>((ref, userId) async {
  final repository = ref.watch(otherProfileRepositoryProvider);
  final useCase = GetInvitableGroups(repository);
  return useCase(userId);
});

/// Provider for invite to group use case
final inviteToGroupProvider = Provider<InviteToGroup>((ref) {
  final repository = ref.watch(otherProfileRepositoryProvider);
  return InviteToGroup(repository);
});
