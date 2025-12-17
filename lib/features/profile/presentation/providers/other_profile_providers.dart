import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/other_profile_entity.dart';
import '../../domain/entities/invite_group_entity.dart';
import '../../domain/repositories/other_profile_repository.dart';
import '../../domain/usecases/get_other_user_profile.dart';
import '../../domain/usecases/get_invitable_groups.dart';
import '../../domain/usecases/invite_to_group.dart';
import '../../domain/usecases/accept_group_invite.dart';
import '../../domain/usecases/decline_group_invite.dart';
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

/// Provider for accept group invite use case
final acceptGroupInviteProvider = Provider<AcceptGroupInvite>((ref) {
  final repository = ref.watch(otherProfileRepositoryProvider);
  return AcceptGroupInvite(repository);
});

/// Provider for decline group invite use case
final declineGroupInviteProvider = Provider<DeclineGroupInvite>((ref) {
  final repository = ref.watch(otherProfileRepositoryProvider);
  return DeclineGroupInvite(repository);
});
