import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/user_info_card.dart';
import '../widgets/memories_section.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/skeletons/profile_skeleton.dart';
import '../../../../routes/app_router.dart';
import '../../domain/entities/profile_entity.dart';
import '../providers/profile_providers.dart';

/// Profile page displaying user information and memories
/// Uses simple provider architecture with automatic sync
class ProfilePage extends ConsumerWidget {
  final bool showBackButton;

  const ProfilePage({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: 'Profile',
        leading: showBackButton
            ? GestureDetector(
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
              )
            : null,
        trailing: GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRouter.settings),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu,
              color: BrandColors.text1,
              size: 24,
            ),
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: Insets.screenH),
          child: Column(
            children: [
              SizedBox(height: Gaps.md),
              UserInfoCardSkeleton(),
              SizedBox(height: Gaps.xl),
              MemoriesSectionSkeleton(count: 4),
              SizedBox(height: Gaps.md),
            ],
          ),
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
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: BrandColors.text2),
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
                onPressed: () => ref.invalidate(currentUserProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            // 🎯 SIMPLE: Just invalidate and wait
            ref.invalidate(currentUserProfileProvider);
            await ref.read(currentUserProfileProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
            child: Column(
              children: [
                const SizedBox(height: Gaps.md),
                UserInfoCard(profile: profile),
                const SizedBox(height: Gaps.xl),
                MemoriesSection(
                  memories: profile.memories,
                  onMemoryTap: (memory) => _onMemoryTap(context, memory),
                ),
                const SizedBox(height: Gaps.md),
              ],
            ),
          ),
        ),
      ),
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
