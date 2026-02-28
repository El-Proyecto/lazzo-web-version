import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/user_info_card.dart';
import '../widgets/upcoming_together_section.dart';
import '../widgets/memories_section.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../routes/app_router.dart';
import '../providers/other_profile_providers.dart';
import '../../../event/domain/entities/event_display_entity.dart';
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
      appBar: CommonAppBar(
        title: 'Profile',
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_ios,
              color: BrandColors.text1,
              size: 20,
            ),
          ),
        ),
        // LAZZO 2.0: Group invite trailing icon removed
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

  // LAZZO 2.0: _handleInvitePressed and _handleGroupSelected removed (group invites removed)

  void _onEventTap(BuildContext context, EventDisplayEntity event) {
    // TODO: Navigate to event detail page
    Navigator.of(context).pushNamed(
      AppRouter.event,
      arguments: {'eventId': event.id},
    );
  }

  void _onMemoryTap(BuildContext context, MemoryEntity memory) {
    Navigator.of(context).pushNamed(
      AppRouter.memory,
      arguments: {
        'memoryId': memory.id,
        'viewSource': 'profile',
      },
    );
  }
}
