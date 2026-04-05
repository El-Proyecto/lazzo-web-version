import 'package:flutter/material.dart';
import '../../../shared/constants/spacing.dart';
import 'shimmer_effect.dart';

/// Skeleton loading state for the Memory page.
///
/// Mimics the real page layout:
/// 1. Subtitle (location • date)
/// 2. Avatar row
/// 3. Stats text
/// 4. Cover mosaic (single full-width hero, 16:9)
/// 5. Photo grid rows
class MemoryPageSkeleton extends StatelessWidget {
  const MemoryPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final coverWidth = screenWidth - Insets.screenH * 2;
    final viewportH = MediaQuery.of(context).size.height;
    final baseHeight = coverWidth / 16 * 9;
    final coverHeight = baseHeight.clamp(viewportH * 0.36, viewportH * 0.42);

    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Info Section ──
            // Location • Date placeholder
            const Center(child: SkeletonBox(width: 160, height: 14)),
            const SizedBox(height: Gaps.sm),

            // Avatar row placeholder
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(4, (index) {
                  return Container(
                    width: 36,
                    height: 36,
                    margin: EdgeInsets.only(left: index == 0 ? 0 : 0),
                    transform: Matrix4.translationValues(
                      index * -8.0,
                      0,
                      0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B2B2B),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1A1A1A),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: Gaps.sm),

            // Stats text placeholder
            const Center(child: SkeletonBox(width: 120, height: 14)),
            const SizedBox(height: Gaps.md),

            // ── Cover Mosaic Skeleton ──
            // Single full-width hero (matches CoverMosaic single-hero)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
              child: Container(
                width: coverWidth,
                height: coverHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2B2B),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: Gaps.xs),

            // ── Grid Rows Skeleton ──
            // 3 rows of 3 photos each
            ...List.generate(3, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: List.generate(3, (colIndex) {
                    return Expanded(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          margin: EdgeInsets.only(
                            right: colIndex < 2 ? 2 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B2B2B),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),

            const SizedBox(height: Gaps.xl),
          ],
        ),
      ),
    );
  }
}
