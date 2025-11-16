import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/manage_memory_providers.dart';

/// Card for selecting and displaying the cover photo
/// Shows placeholder when no cover is selected
/// Shows photo with remove button when cover is selected
class CoverSelectionCard extends StatelessWidget {
  final ManagePhotoItem? selectedPhoto;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const CoverSelectionCard({
    super.key,
    this.selectedPhoto,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth - (Insets.screenH * 2);

    // Calculate dimensions based on photos_layout_sizes.md
    // Container: 4 columns × 2 rows
    final colW = (containerWidth - (Gaps.xs * 3)) / 4;

    // For single cover, use B (2×2 cells)
    final coverWidth = colW * 2 + Gaps.xs;
    final coverHeight = colW * 2 + Gaps.xs;

    if (selectedPhoto == null) {
      // Placeholder state
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: coverWidth,
          height: coverHeight,
          decoration: BoxDecoration(
            color: BrandColors.bg2,
            border: Border.all(color: BrandColors.border, width: 1),
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_outline,
                color: BrandColors.text2,
                size: IconSizes.lg,
              ),
              const SizedBox(height: Gaps.sm),
              Text(
                'Tap to select a cover!',
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Photo selected state
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: coverWidth,
            height: coverHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.md),
              image: DecorationImage(
                image: NetworkImage(
                    selectedPhoto!.thumbnailUrl ?? selectedPhoto!.url),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Remove button
          if (onRemove != null)
            Positioned(
              top: Gaps.xs,
              right: Gaps.xs,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xCC000000), // 80% black
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
