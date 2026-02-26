import 'package:flutter/material.dart';
import '../../../shared/constants/spacing.dart';
import 'shimmer_effect.dart';

/// Skeleton placeholder for the hero HomeEventCard (Next Event / Live Event).
///
/// Matches the approximate dimensions and layout of the real card so
/// there's no layout shift when data arrives.
class HomeEventCardSkeleton extends StatelessWidget {
  const HomeEventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji + title row
            const Row(
              children: [
                SkeletonBox(width: 40, height: 40, borderRadius: 20),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 16),
                    SizedBox(height: 6),
                    SkeletonBox(width: 100, height: 12),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // Attendee avatars row
            Row(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                  child: const SkeletonBox(width: 32, height: 32, borderRadius: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Bottom bar
            const SkeletonBox(width: double.infinity, height: 14),
          ],
        ),
      ),
    );
  }
}
