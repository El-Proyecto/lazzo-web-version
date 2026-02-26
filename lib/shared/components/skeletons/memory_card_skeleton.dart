import 'package:flutter/material.dart';
import '../../../shared/constants/spacing.dart';
import 'shimmer_effect.dart';

/// Skeleton placeholder for the horizontal RecentMemoryCard list.
class MemoryCardSkeleton extends StatelessWidget {
  final double width;
  const MemoryCardSkeleton({super.key, this.width = 160});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        width: width,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(Radii.smAlt),
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
    );
  }
}
