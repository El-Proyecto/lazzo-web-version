import 'package:flutter/material.dart';
import '../../../shared/constants/spacing.dart';
import 'shimmer_effect.dart';

/// Skeleton placeholder for EventSmallCard rows (Confirmed / Pending lists).
class EventSmallCardSkeleton extends StatelessWidget {
  const EventSmallCardSkeleton({super.key});

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
                  SkeletonBox(width: 120, height: 14),
                  SizedBox(height: 6),
                  SkeletonBox(width: 80, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A section of N skeleton small cards, mimicking a list.
class EventSmallCardSkeletonList extends StatelessWidget {
  final int count;
  const EventSmallCardSkeletonList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i < count - 1 ? Gaps.sm : 0),
          child: const EventSmallCardSkeleton(),
        ),
      ),
    );
  }
}
