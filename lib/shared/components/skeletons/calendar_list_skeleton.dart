import 'package:flutter/material.dart';
import '../../../shared/constants/spacing.dart';
import 'shimmer_effect.dart';

/// Skeleton placeholder for the calendar list view loading state.
/// Shows simulated day headers and event card placeholders.
class CalendarListSkeleton extends StatelessWidget {
  const CalendarListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.sectionH,
        vertical: Gaps.md,
      ),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // First day group
        _buildDayGroup(3),
        const SizedBox(height: Gaps.lg),
        // Second day group
        _buildDayGroup(2),
        const SizedBox(height: Gaps.lg),
        // Third day group
        _buildDayGroup(1),
      ],
    );
  }

  Widget _buildDayGroup(int cardCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header skeleton
        const ShimmerEffect(
          child: SkeletonBox(width: 160, height: 16),
        ),
        const SizedBox(height: Gaps.sm),
        // Event card skeletons
        for (int i = 0; i < cardCount; i++) ...[
          const _CalendarEventCardSkeleton(),
          if (i < cardCount - 1) const SizedBox(height: Gaps.sm),
        ],
      ],
    );
  }
}

/// Skeleton for a single calendar event card
class _CalendarEventCardSkeleton extends StatelessWidget {
  const _CalendarEventCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(Radii.smAlt),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: const Row(
          children: [
            // Emoji circle
            SkeletonBox(width: 40, height: 40, borderRadius: 20),
            SizedBox(width: 12),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonBox(width: 140, height: 14),
                  SizedBox(height: 6),
                  SkeletonBox(width: 90, height: 12),
                ],
              ),
            ),
            // Status badge
            SkeletonBox(width: 60, height: 24, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}
