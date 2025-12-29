import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/dialogs/confirmation_dialog.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/common/invite_bottom_sheet.dart';
import 'package:app/config/app_config.dart';
import '../../../group_invites/presentation/providers/group_invites_providers.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../groups/domain/entities/group_entity.dart';
import '../../../groups/presentation/pages/edit_group_page.dart';
import '../providers/group_hub_providers.dart';
import '../widgets/group_shortcut_action.dart';
import '../widgets/group_member_list_item.dart';
import '../../domain/entities/group_member_entity.dart';
import 'group_photos_page.dart';
import '../../../groups/presentation/providers/groups_provider.dart' as groups;

class GroupDetailsPage extends ConsumerWidget {
  final String groupId;

  const GroupDetailsPage({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(groupDetailsProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: _buildAppBar(context, ref, detailsAsync.value),
      body: SafeArea(
        child: detailsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: BrandColors.planning),
          ),
          error: (error, stackTrace) => _buildErrorState(context, ref),
          data: (details) => SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: Gaps.lg),

                // Group info section (reusing same style as group_hub)
                _buildGroupInfo(
                    details.name, details.photoUrl, details.memberCount),

                const SizedBox(height: Gaps.xl),

                // Shortcuts section
                _buildShortcuts(context, ref, details.isMuted, details.name),

                const SizedBox(height: Gaps.lg),

                // Members list
                membersAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Pads.sectionH),
                      child: CircularProgressIndicator(
                          color: BrandColors.planning),
                    ),
                  ),
                  error: (error, stackTrace) =>
                      _buildMembersErrorState(context, ref),
                  data: (members) => _buildMembersList(
                    context,
                    ref,
                    members,
                    details.isCurrentUserAdmin,
                  ),
                ),

                const SizedBox(height: Gaps.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    dynamic details,
  ) {
    final isAdmin = details?.isCurrentUserAdmin ?? false;

    return CommonAppBar(
      title: 'Group Details',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
        onPressed: () => Navigator.of(context).pop(),
      ),
      trailing: isAdmin
          ? IconButton(
              icon: const Icon(Icons.edit_outlined, color: BrandColors.text1),
              onPressed: () async {
                // Convert GroupDetailsEntity to GroupEntity for edit page
                final groupEntity = GroupEntity(
                  id: groupId,
                  name: details!.name,
                  photoUrl: details.photoUrl,
                  permissions: details.permissions,
                );

                final result = await Navigator.of(context).push<GroupEntity>(
                  MaterialPageRoute(
                    builder: (context) => EditGroupPage(group: groupEntity),
                  ),
                );

                // Refresh group details if group was updated
                if (result != null && context.mounted) {
                  ref.invalidate(groupDetailsProvider(groupId));
                }
              },
            )
          : const SizedBox(width: 28, height: 28),
    );
  }

  Widget _buildGroupInfo(String name, String? photoUrl, int memberCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
      child: Column(
        children: [
          // Group photo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: BrandColors.bg3,
            ),
            child: photoUrl == null || photoUrl.isEmpty
                ? const Icon(
                    Icons.group,
                    size: 40,
                    color: BrandColors.text2,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      photoUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.group,
                          size: 40,
                          color: BrandColors.text2,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: BrandColors.text2,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: Gaps.md),

          // Group name
          Text(
            name,
            style: AppText.headlineMedium.copyWith(
              color: BrandColors.text1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Gaps.xs),

          // Member count
          Text(
            '$memberCount Members',
            style: AppText.bodyMediumEmph.copyWith(
              color: BrandColors.text2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcuts(
      BuildContext context, WidgetRef ref, bool isMuted, String groupName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
      child: Row(
        children: [
          Expanded(
            child: GroupShortcutAction(
              icon: Icons.photo_library_outlined,
              label: 'Photos',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GroupPhotosPage(
                      groupId: groupId,
                      eventName: groupName,
                      locationAndDate:
                          'All memories', // Shows photos from all events
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: GroupShortcutAction(
              icon: Icons.person_add_outlined,
              label: 'Invite',
              onTap: () {
                _showInviteBottomSheet(context, ref);
              },
            ),
          ),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: GroupShortcutAction(
              icon: isMuted
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_outlined,
              label: isMuted ? 'Unmute' : 'Mute',
              onTap: () {
                ref.read(groupDetailsProvider(groupId).notifier).toggleMute();
                _showMuteBanner(context, !isMuted);
              },
            ),
          ),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: GroupShortcutAction(
              icon: Icons.logout,
              label: 'Leave',
              iconColor: BrandColors.cantVote,
              onTap: () {
                _showLeaveGroupDialog(context, ref);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(
    BuildContext context,
    WidgetRef ref,
    List<GroupMemberEntity> members,
    bool isCurrentUserAdmin,
  ) {
    // Sort: current user first, then admins, then regular members
    final sortedMembers = List<GroupMemberEntity>.from(members)
      ..sort((a, b) {
        if (a.isCurrentUser) return -1;
        if (b.isCurrentUser) return 1;
        if (a.isAdmin && !b.isAdmin) return -1;
        if (!a.isAdmin && b.isAdmin) return 1;
        return a.name.compareTo(b.name);
      });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Insets.screenH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(
                top: Pads.sectionH,
                left: Pads.sectionH,
                right: Pads.sectionH,
                bottom: Pads.ctlVXs),
            child: Text(
              'Members',
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text1,
              ),
            ),
          ),

          // Members list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedMembers.length,
            separatorBuilder: (context, index) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: Pads.sectionH),
              child: Divider(
                color: BrandColors.bg3,
                height: 1,
              ),
            ),
            itemBuilder: (context, index) {
              final member = sortedMembers[index];
              return GroupMemberListItem(
                member: member,
                isCurrentUserAdmin: isCurrentUserAdmin,
                onTap: () {
                  if (member.isCurrentUser) {
                    // Navigate to own profile
                    Navigator.pushNamed(context, AppRouter.profile);
                  } else {
                    // Navigate to other user profile
                    Navigator.pushNamed(
                      context,
                      AppRouter.otherProfile,
                      arguments: {'userId': member.id},
                    );
                  }
                },
                onPromoteToAdmin: () {
                  _showPromoteDialog(context, ref, member);
                },
                onDemoteFromAdmin: () {
                  _showDemoteDialog(context, ref, member);
                },
                onRemoveFromGroup: () {
                  _showRemoveMemberDialog(context, ref, member);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Pads.sectionH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: BrandColors.text2,
            ),
            const SizedBox(height: Gaps.lg),
            Text(
              'Error loading group details',
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gaps.md),
            TextButton(
              onPressed: () {
                ref.read(groupDetailsProvider(groupId).notifier).refresh();
              },
              child: Text(
                'Try again',
                style: AppText.labelLarge.copyWith(
                  color: BrandColors.planning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersErrorState(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(Pads.sectionH),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: BrandColors.text2,
          ),
          const SizedBox(height: Gaps.md),
          Text(
            'Error loading members',
            style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
          ),
          const SizedBox(height: Gaps.sm),
          TextButton(
            onPressed: () {
              ref.read(groupMembersProvider(groupId).notifier).refresh();
            },
            child: Text(
              'Try again',
              style: AppText.labelLarge.copyWith(color: BrandColors.planning),
            ),
          ),
        ],
      ),
    );
  }

  void _showMuteBanner(BuildContext context, bool isMuted) {
    TopBanner.show(
      context,
      message:
          isMuted ? 'Group notifications muted' : 'Group notifications unmuted',
      duration: const Duration(seconds: 2),
    );
  }

  void _showInviteBottomSheet(BuildContext context, WidgetRef ref) async {
    try {
      final createInvite = ref.read(createGroupInviteLinkProvider);
      final result = await createInvite.call(groupId: groupId);

      final inviteUrl = '${AppConfig.invitesBaseUrl}/invite/${result.token}';
      final groupName = ref.read(groupDetailsProvider(groupId)).value?.name ?? 'Group Name';

      InviteBottomSheet.show(
        context: context,
        inviteUrl: inviteUrl,
        entityName: groupName,
        entityType: 'group',
      );
    } catch (e) {
      // Fallback to simple URL if RPC fails
      final fallback = '${AppConfig.invitesBaseUrl}/invite';
      InviteBottomSheet.show(
        context: context,
        inviteUrl: fallback,
        entityName: ref.read(groupDetailsProvider(groupId)).value?.name ?? 'Group Name',
        entityType: 'group',
      );
      TopBanner.showInfo(context, message: 'Unable to generate invite link');
    }
  }

  void _showLeaveGroupDialog(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.read(groupDetailsProvider(groupId));
    final groupName = detailsAsync.value?.name ?? 'this group';

    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        title: 'Leave Group?',
        message:
            'Are you sure you want to leave $groupName? You can rejoin later with an invite.',
        confirmText: 'Leave',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: () async {
          // OPTIMISTIC UI: invalidate groups immediately and navigate back
          final controller = ref.read(groups.groupsControllerProvider);

          // Close dialog first
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }

          try {
            // Optimistically invalidate groups provider to remove from list
            ref.invalidate(groups.groupsProvider);
            ref.invalidate(groups.archivedGroupsProvider);

            // Navigate back to groups page immediately (group already removed from list)
            if (context.mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.of(context).pushReplacementNamed(AppRouter.groups);
            }

            // Call server in background
            await controller.leaveGroupOptimistic(groupId);

            // Show success feedback
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Left "$groupName"'),
                  backgroundColor: BrandColors.planning,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            // Show error feedback (rollback already happened in controller)
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Failed to leave group: ${e.toString().replaceAll('Exception: ', '')}'),
                  backgroundColor: BrandColors.cantVote,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showPromoteDialog(
    BuildContext context,
    WidgetRef ref,
    GroupMemberEntity member,
  ) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Promote to Admin?',
        message:
            'Promote ${member.name} to group admin? They will have full admin privileges.',
        confirmText: 'Promote',
        cancelText: 'Cancel',
        onConfirm: () async {
          // 1. OPTIMISTIC UPDATE - UI responds immediately
          ref
              .read(groupMembersProvider(groupId).notifier)
              .updateMemberRoleOptimistically(member.id, true);

          try {
            // 2. SERVER UPDATE - execute in background
            final updateMemberRole = ref.read(updateMemberRoleUseCaseProvider);
            await updateMemberRole(groupId, member.id, true);

            // 3. CONFIRM - refresh from server to ensure consistency
            await ref.read(groupMembersProvider(groupId).notifier).refresh();

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${member.name} is now an admin'),
                backgroundColor: BrandColors.planning,
              ),
            );
          } catch (e) {
            // 4. ROLLBACK - revert optimistic update on error
            await ref.read(groupMembersProvider(groupId).notifier).refresh();

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to promote: $e'),
                backgroundColor: BrandColors.cantVote,
              ),
            );
          }
        },
      ),
    );
  }

  void _showDemoteDialog(
    BuildContext context,
    WidgetRef ref,
    GroupMemberEntity member,
  ) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Demote from Admin?',
        message:
            'Remove ${member.name}\'s admin privileges? They will become a regular member.',
        confirmText: 'Demote',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: () async {
          // 1. OPTIMISTIC UPDATE - UI responds immediately
          ref
              .read(groupMembersProvider(groupId).notifier)
              .updateMemberRoleOptimistically(member.id, false);

          try {
            // 2. SERVER UPDATE - execute in background
            final updateMemberRole = ref.read(updateMemberRoleUseCaseProvider);
            await updateMemberRole(groupId, member.id, false);

            // 3. CONFIRM - refresh from server to ensure consistency
            await ref.read(groupMembersProvider(groupId).notifier).refresh();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${member.name} is now a regular member'),
                  backgroundColor: BrandColors.planning,
                ),
              );
            }
          } catch (e) {
            // 4. ROLLBACK - revert optimistic update on error
            await ref.read(groupMembersProvider(groupId).notifier).refresh();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Failed to demote: ${e.toString().replaceAll('Exception: ', '')}'),
                  backgroundColor: BrandColors.cantVote,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showRemoveMemberDialog(
    BuildContext context,
    WidgetRef ref,
    GroupMemberEntity member,
  ) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Remove Member?',
        message: member.isAdmin
            ? 'Remove ${member.name} (admin) from this group? They can rejoin with an invite.'
            : 'Remove ${member.name} from this group? They can rejoin with an invite.',
        confirmText: 'Remove',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: () async {
          // 1. OPTIMISTIC UPDATE - UI responds immediately
          ref
              .read(groupMembersProvider(groupId).notifier)
              .removeMemberOptimistically(member.id);

          try {
            // 2. SERVER UPDATE - execute in background
            final removeMember = ref.read(removeMemberUseCaseProvider);
            await removeMember(groupId, member.id);

            // 3. CONFIRM - refresh from server to ensure consistency
            await ref.read(groupMembersProvider(groupId).notifier).refresh();

            if (context.mounted) {
              // Refresh group details to update member count
              ref.invalidate(groupDetailsProvider(groupId));

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${member.name} has been removed'),
                  backgroundColor: BrandColors.planning,
                ),
              );
            }
          } catch (e) {
            // 4. ROLLBACK - revert optimistic update on error
            await ref.read(groupMembersProvider(groupId).notifier).refresh();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Failed to remove: ${e.toString().replaceAll('Exception: ', '')}'),
                  backgroundColor: BrandColors.cantVote,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
