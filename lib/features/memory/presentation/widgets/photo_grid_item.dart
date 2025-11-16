import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/manage_memory_providers.dart';

/// Grid item for displaying a photo in the manage memory grid
/// Supports selection mode with checkboxes
/// Non-selectable photos (other users' photos for non-hosts) are dimmed
class PhotoGridItem extends StatelessWidget {
  final ManagePhotoItem photo;
  final double width;
  final double height;
  final bool canSelect;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onSelectionChanged;

  const PhotoGridItem({
    super.key,
    required this.photo,
    required this.width,
    required this.height,
    this.canSelect = true,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onTap,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Photo image with border when selected
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.sm),
              color: BrandColors.bg2,
              // Green border when selected in selection mode
              border: isSelectionMode && isSelected
                  ? Border.all(
                      color: BrandColors.planning,
                      width: 3,
                    )
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: ColorFiltered(
              colorFilter: isSelectionMode && !canSelect
                  ? const ColorFilter.mode(
                      Color(0x99000000), // Darken non-selectable
                      BlendMode.darken,
                    )
                  : const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.multiply,
                    ),
              child: Image.network(
                photo.thumbnailUrl ?? photo.url,
                fit: BoxFit.cover,
                width: width,
                height: height,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: BrandColors.bg2,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: BrandColors.text2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Selection checkbox overlay (only show in selection mode)
          if (isSelectionMode && canSelect)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? BrandColors.planning
                      : BrandColors.bg2.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: BrandColors.text1,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: BrandColors.text1,
                        size: 16,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
