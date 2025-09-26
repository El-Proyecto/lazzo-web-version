import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/profile_app_bar.dart';
import '../../../../shared/components/cards/user_info_card.dart';
import '../../../../shared/components/sections/memories_section.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/profile_entity.dart';
import '../providers/profile_providers.dart';

/// Profile page displaying user information and memories
/// Follows mobile-first design and responsive layout
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: ProfileAppBar(onEditPressed: () => _onEditProfile(context)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: BrandColors.text2),
              const SizedBox(height: Gaps.md),
              Text(
                'Error loading profile',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: BrandColors.text2),
              ),
              const SizedBox(height: Gaps.sm),
              TextButton(
                onPressed: () => ref.refresh(currentUserProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
          child: Column(
            children: [
              const SizedBox(height: Gaps.lg),

              // User Info Section
              UserInfoCard(
                name: profile.name,
                profileImageUrl: profile.profileImageUrl,
                location: profile.location,
                birthday: profile.birthday,
              ),

              const SizedBox(height: Gaps.lg), // Reduced from 40px to 24px
              // Memories Section
              MemoriesSection(
                memories: profile.memories,
                onMemoryTap: (memory) => _onMemoryTap(context, memory),
              ),

              const SizedBox(height: Gaps.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _onEditProfile(BuildContext context) {
    Navigator.of(context).pushNamed('/edit-profile');
  }

  void _onMemoryTap(BuildContext context, MemoryEntity memory) {
    // TODO: Navigate to memory detail page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Memory detail - Coming soon!',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
}
