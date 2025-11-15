import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/manage_memory_providers.dart';

/// Grid item for displaying a photo in the manage memory grid
/// Shows remove button for user's own photos
/// All photos are displayed in portrait orientation (4:5 aspect ratio)
class PhotoGridItem extends StatelessWidget {
  final ManagePhotoItem photo;
  final double width;
  final double height;
  final bool showRemoveButton;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const PhotoGridItem({
    super.key,
    required this.photo,
    required this.width,
    required this.height,
    this.showRemoveButton = false,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.sm),
              color: BrandColors.bg2,
              image: DecorationImage(
                image: NetworkImage(photo.thumbnailUrl ?? photo.url),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Remove button for user photos
          if (showRemoveButton && onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xCC000000), // 80% black
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
