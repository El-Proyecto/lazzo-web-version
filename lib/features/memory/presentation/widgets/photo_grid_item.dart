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
          // Photo image
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.sm),
              color: BrandColors.bg2,
              image: DecorationImage(
                image: NetworkImage(photo.thumbnailUrl ?? photo.url),
                fit: BoxFit.cover,
                colorFilter: isSelectionMode && !canSelect
                    ? const ColorFilter.mode(
                        Color(
                            0x99000000), // Darken non-selectable only in selection mode
                        BlendMode.darken,
                      )
                    : null,
              ),
            ),
          ),

          // Selection checkbox (only show if can select)
          if (canSelect && (isSelectionMode || isSelected))
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => onSelectionChanged?.call(!isSelected),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? BrandColors.planning : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? BrandColors.planning : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
