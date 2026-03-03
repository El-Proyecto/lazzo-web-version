import 'package:flutter/material.dart';
import '../../../shared/constants/spacing.dart';
import 'shimmer_effect.dart';

/// Skeleton for the UserInfoCard (avatar + name + location)
class UserInfoCardSkeleton extends StatelessWidget {
  const UserInfoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
              borderRadius: BorderRadius.circular(90),
            ),
          ),
          const SizedBox(height: Gaps.sm),
          // Name
          const SkeletonBox(width: 140, height: 18),
          const SizedBox(height: Gaps.xxs),
          // Location
          const SkeletonBox(width: 100, height: 14),
        ],
      ),
    );
  }
}

/// Skeleton for a single memory card (square, matching MemoryCard aspect ratio)
class MemoryGridCardSkeleton extends StatelessWidget {
  const MemoryGridCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          padding: const EdgeInsets.all(12),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SkeletonBox(width: 100, height: 14),
              SizedBox(height: 6),
              SkeletonBox(width: 70, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the memories grid section in the profile page
/// Shows section title placeholder + 2-column grid of skeleton cards
class MemoriesSectionSkeleton extends StatelessWidget {
  final int count;
  const MemoriesSectionSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title skeleton
        const ShimmerEffect(
          child: SkeletonBox(width: 100, height: 18),
        ),
        const SizedBox(height: Gaps.sm),
        // 2-column grid of skeleton cards
        LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                for (int i = 0; i < count; i += 2)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i + 2 < count ? Gaps.xs : 0,
                    ),
                    child: const Row(
                      children: [
                        Expanded(child: MemoryGridCardSkeleton()),
                        SizedBox(width: Gaps.xs),
                        Expanded(child: MemoryGridCardSkeleton()),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
