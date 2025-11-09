import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/other_profile_app_bar.dart';
import '../widgets/user_info_card.dart';
import '../widgets/upcoming_together_section.dart';
import '../widgets/memories_section.dart';
import '../widgets/invite_to_group_bottom_sheet.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../providers/other_profile_providers.dart';
import '../../../group_hub/domain/entities/group_event_entity.dart';
import '../../domain/entities/profile_entity.dart';

/// Other user's profile page
/// Shows profile information, shared upcoming events, and shared memories
class OtherProfilePage extends ConsumerWidget {
  final String userId;

  const OtherProfilePage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(otherUserProfileProvider(userId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: OtherProfileAppBar(
        onInvitePressed: () => _handleInvitePressed(context, ref),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: BrandColors.planning),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: BrandColors.text2,
              ),
              const SizedBox(height: Gaps.md),
              Text(
                'Error loading profile',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: BrandColors.text2,
                    ),
              ),
              const SizedBox(height: Gaps.sm),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BrandColors.text2,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gaps.md),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(otherUserProfileProvider(userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(otherUserProfileProvider(userId));
            await ref.read(otherUserProfileProvider(userId).future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // User info
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Insets.screenH),
                  child: Column(
                    children: [
                      const SizedBox(height: Gaps.md),
                      UserInfoCard(
                        profile: ProfileEntity(
                          id: profile.id,
                          name: profile.name,
                          profileImageUrl: profile.profileImageUrl,
                          location: profile.location,
                          birthday: profile.birthday,
                        ),
                      ),
                      const SizedBox(height: Gaps.xl),
                    ],
                  ),
                ),

                // Upcoming Together section
                UpcomingTogetherSection(
                  events: profile.upcomingTogether,
                  onEventTap: (event) => _onEventTap(context, event),
                ),

                if (profile.upcomingTogether.isNotEmpty)
                  const SizedBox(height: Gaps.xl),

                // Memories Together section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Insets.screenH),
                  child: MemoriesSection(
                    title: 'Shared Memories',
                    memories: profile.memoriesTogether,
                    onMemoryTap: (memory) => _onMemoryTap(context, memory),
                  ),
                ),

                const SizedBox(height: Gaps.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleInvitePressed(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: BrandColors.planning),
        ),
      );

      // Fetch groups and profile in parallel
      final groups = await ref.read(invitableGroupsProvider(userId).future);
      final profile = await ref.read(otherUserProfileProvider(userId).future);

      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show bottom sheet
        InviteToGroupBottomSheet.show(
          context: context,
          userName: profile.name,
          groups: groups,
          onGroupsSelected: (groupIds) =>
              _handleGroupsSelected(context, ref, groupIds, profile.name),
        );
      }
    } catch (e) {
      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        TopBanner.showError(
          context,
          message: 'Failed to load groups',
        );
      }
    }
  }

  void _handleGroupsSelected(
    BuildContext context,
    WidgetRef ref,
    List<String> groupIds,
    String userName,
  ) async {
    try {
      final inviteUseCase = ref.read(inviteToGroupProvider);

      // Send invitations to all selected groups
      int successCount = 0;
      for (final groupId in groupIds) {
        final success = await inviteUseCase(
          userId: userId,
          groupId: groupId,
        );
        if (success) successCount++;
      }

      if (context.mounted) {
        if (successCount == groupIds.length) {
          final message = groupIds.length == 1
              ? 'Invitation sent to $userName'
              : '$successCount invitations sent to $userName';
          TopBanner.showSuccess(
            context,
            message: message,
          );
        } else if (successCount > 0) {
          TopBanner.showInfo(
            context,
            message: '$successCount of ${groupIds.length} invitations sent',
          );
        } else {
          TopBanner.showError(
            context,
            message: 'Failed to send invitations',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        TopBanner.showError(
          context,
          message: 'Error sending invitations',
        );
      }
    }
  }

  void _onEventTap(BuildContext context, GroupEventEntity event) {
    // TODO: Navigate to event detail page
    TopBanner.showInfo(
      context,
      message: 'Event detail - Coming soon!',
    );
  }

  void _onMemoryTap(BuildContext context, MemoryEntity memory) {
    // TODO: Navigate to memory detail page
    TopBanner.showInfo(
      context,
      message: 'Memory detail - Coming soon!',
    );
  }
}
