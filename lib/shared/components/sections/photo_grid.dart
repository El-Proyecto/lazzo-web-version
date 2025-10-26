import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../themes/colors.dart';

/// Photo grid widget for displaying all non-cover photos
/// Following the layout spec from photos_layout_sizes.md
class PhotoGrid extends StatelessWidget {
  final List<GridPhotoData> photos;
  final VoidCallback? onPhotoTap;

  const PhotoGrid({
    super.key,
    required this.photos,
    this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = Insets.screenH; // 16px
        const gap = Gaps.xs; // 8px
        const columns = 3;

        final screenW = constraints.maxWidth;
        final colW = (screenW - padding * 2 - gap * 2) / columns;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: padding),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: photos.map((photo) {
              final isLandscape = !photo.isPortrait;
              final width = isLandscape ? colW * 2 + gap : colW;
              final height = _calculateHeight(
                  colW, photo.isPortrait, isLandscape ? colW * 2 + gap : colW);

              return SizedBox(
                width: width,
                height: height,
                child: GestureDetector(
                  onTap: onPhotoTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: Image.network(
                      photo.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: BrandColors.bg3,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: BrandColors.bg3,
                          child: const Icon(
                            Icons.broken_image,
                            color: BrandColors.text2,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Calculate tile height based on orientation
  /// Portrait: 4:5 aspect ratio → height = colW * 5/4
  /// Landscape: 16:9 aspect ratio → height = spanW * 9/16
  double _calculateHeight(double colW, bool isPortrait, double width) {
    if (isPortrait) {
      return colW * 5 / 4;
    } else {
      // Landscape spans 2 columns
      return width * 9 / 16;
    }
  }
}

/// Data model for a grid photo
class GridPhotoData {
  final String id;
  final String imageUrl;
  final bool isPortrait;

  const GridPhotoData({
    required this.id,
    required this.imageUrl,
    required this.isPortrait,
  });
}
