import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/dialogs/confirmation_dialog.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/group_hub_providers.dart';
import '../widgets/group_shortcut_action.dart';
import '../widgets/group_member_list_item.dart';
import '../../domain/entities/group_member_entity.dart';

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
                _buildShortcuts(context, ref, details.isMuted),

                const SizedBox(height: Gaps.xl),

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
              onPressed: () {
                // TODO: Navigate to edit group page
                print('Navigate to edit group');
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
              image: photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoUrl == null
                ? const Icon(
                    Icons.group,
                    size: 40,
                    color: BrandColors.text2,
                  )
                : null,
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

  Widget _buildShortcuts(BuildContext context, WidgetRef ref, bool isMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
      child: Row(
        children: [
          Expanded(
            child: GroupShortcutAction(
              icon: Icons.photo_library_outlined,
              label: 'Photos',
              onTap: () {
                // TODO: Navigate to group photos
              },
            ),
          ),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: GroupShortcutAction(
              icon: Icons.person_add_outlined,
              label: 'Invite',
              onTap: () {
                // TODO: Show add member flow
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
                _showLeaveGroupDialog(context);
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
            padding: const EdgeInsets.all(Pads.sectionH),
            child: Row(
              children: [
                Text(
                  'Members',
                  style: AppText.titleMediumEmph.copyWith(
                    color: BrandColors.text1,
                  ),
                ),
                const SizedBox(width: Gaps.xs),
                Text(
                  '${members.length}',
                  style: AppText.titleMediumEmph.copyWith(
                    color: BrandColors.text2,
                  ),
                ),
              ],
            ),
          ),

          // Members list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedMembers.length,
            separatorBuilder: (context, index) => const Divider(
              color: BrandColors.bg3,
              height: 1,
              indent: Pads.sectionH + 40 + Gaps.md,
              endIndent: Pads.sectionH,
            ),
            itemBuilder: (context, index) {
              final member = sortedMembers[index];
              return GroupMemberListItem(
                member: member,
                isCurrentUserAdmin: isCurrentUserAdmin,
                onTap: () {
                  // TODO: Navigate to member profile
                  print('Navigate to profile: ${member.id}');
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

  void _showLeaveGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Leave Group?',
        message:
            'Are you sure you want to leave this group? You can rejoin later with an invite.',
        confirmText: 'Leave',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: () {
          // TODO: Implement leave group logic
          print('Leave group');
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
        onConfirm: () {
          // TODO: Implement promote logic
          print('Promote ${member.id} to admin');
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
        onConfirm: () {
          // TODO: Implement demote logic
          print('Demote ${member.id} from admin');
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
        message:
            'Remove ${member.name} from this group? They can rejoin with an invite.',
        confirmText: 'Remove',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: () {
          // TODO: Implement remove member logic
          print('Remove ${member.id} from group');
        },
      ),
    );
  }
}
