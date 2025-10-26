import 'package:flutter/material.dart';
import '../../constants/spacing.dart';

/// Layout data for a single tile in the cover mosaic
class CoverTileLayout {
  final int column; // 1-4
  final int row; // 1-2
  final int columnSpan; // 1-2
  final int rowSpan; // 1-2

  const CoverTileLayout({
    required this.column,
    required this.row,
    required this.columnSpan,
    required this.rowSpan,
  });
}

/// Cover mosaic widget that displays 1-3 cover photos
/// Following the layout spec from photos_layout_sizes.md
class CoverMosaic extends StatelessWidget {
  final List<CoverPhotoData> covers;
  final double containerWidth;
  final VoidCallback? onPhotoTap;

  const CoverMosaic({
    super.key,
    required this.covers,
    required this.containerWidth,
    this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    if (covers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate cell dimensions based on spec
    const padding = Insets.screenH; // 16px
    const gap = Gaps.xs; // 8px
    final colW = (containerWidth - padding * 2 - gap * 3) / 4;

    // Get layouts based on number of covers and their orientations
    final layouts = _calculateLayouts(covers);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: padding),
      child: SizedBox(
        height: colW * 2 + gap, // 2 rows
        child: Stack(
          children: List.generate(
            covers.length,
            (index) {
              final cover = covers[index];
              final layout = layouts[index];

              final width =
                  colW * layout.columnSpan + (layout.columnSpan - 1) * gap;
              final height = colW * layout.rowSpan + (layout.rowSpan - 1) * gap;
              final left = (layout.column - 1) * (colW + gap);
              final top = (layout.row - 1) * (colW + gap);

              return Positioned(
                left: left,
                top: top,
                width: width,
                height: height,
                child: GestureDetector(
                  onTap: onPhotoTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: Image.network(
                      cover.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFF2B2B2B),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF2B2B2B),
                          child: const Icon(
                            Icons.broken_image,
                            color: Color(0xFFA6A6A6),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Calculate tile layouts based on cover count and orientations
  List<CoverTileLayout> _calculateLayouts(List<CoverPhotoData> covers) {
    final count = covers.length.clamp(1, 3);
    final orientations = covers.map((c) => c.isPortrait).toList();

    if (count == 1) {
      // Single cover → Big (2×2) centered at cols 2-3, rows 1-2
      return const [
        CoverTileLayout(column: 2, row: 1, columnSpan: 2, rowSpan: 2),
      ];
    }

    if (count == 2) {
      final isV = orientations[0];
      final isV2 = orientations[1];

      if (isV && !isV2) {
        // [V, H] → V(col 1, rows 1-2) + H(cols 2-3, row 1)
        return const [
          CoverTileLayout(column: 1, row: 1, columnSpan: 1, rowSpan: 2),
          CoverTileLayout(column: 2, row: 1, columnSpan: 2, rowSpan: 1),
        ];
      } else if (!isV && isV2) {
        // [H, V] → H(cols 1-2, row 1) + V(col 4, rows 1-2)
        return const [
          CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 1),
          CoverTileLayout(column: 4, row: 1, columnSpan: 1, rowSpan: 2),
        ];
      } else if (isV && isV2) {
        // [V, V] → B(cols 1-2, rows 1-2) + V(col 4, rows 1-2)
        return const [
          CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 2),
          CoverTileLayout(column: 4, row: 1, columnSpan: 1, rowSpan: 2),
        ];
      } else {
        // [H, H] → H(cols 1-2, row 1) + H(cols 3-4, row 1)
        return const [
          CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 1),
          CoverTileLayout(column: 3, row: 1, columnSpan: 2, rowSpan: 1),
        ];
      }
    }

    // count == 3
    final isV1 = orientations[0];
    final isV2 = orientations[1];
    final isV3 = orientations[2];

    if (isV1 && !isV2 && !isV3) {
      // [V, H, H] → V(col 1) + H(cols 2-3, row 1) + H(cols 2-3, row 2)
      return const [
        CoverTileLayout(column: 1, row: 1, columnSpan: 1, rowSpan: 2),
        CoverTileLayout(column: 2, row: 1, columnSpan: 2, rowSpan: 1),
        CoverTileLayout(column: 2, row: 2, columnSpan: 2, rowSpan: 1),
      ];
    } else if (!isV1 && isV2 && !isV3) {
      // [H, V, H] → H(cols 1-2, row 1) + V(col 4) + H(cols 1-2, row 2)
      return const [
        CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 1),
        CoverTileLayout(column: 4, row: 1, columnSpan: 1, rowSpan: 2),
        CoverTileLayout(column: 1, row: 2, columnSpan: 2, rowSpan: 1),
      ];
    } else if (!isV1 && !isV2 && isV3) {
      // [H, H, V] → H(cols 1-2, row 1) + H(cols 3-4, row 1) + V(col 4, rows 1-2)
      return const [
        CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 1),
        CoverTileLayout(column: 3, row: 1, columnSpan: 2, rowSpan: 1),
        CoverTileLayout(column: 4, row: 1, columnSpan: 1, rowSpan: 2),
      ];
    } else if (isV1 && isV2 && !isV3) {
      // [V, V, H] → V(col 1) + V(col 2) + H(cols 3-4, row 2)
      return const [
        CoverTileLayout(column: 1, row: 1, columnSpan: 1, rowSpan: 2),
        CoverTileLayout(column: 2, row: 1, columnSpan: 1, rowSpan: 2),
        CoverTileLayout(column: 3, row: 2, columnSpan: 2, rowSpan: 1),
      ];
    } else if (isV1 && isV2 && isV3) {
      // [V, V, V] → B(cols 1-2) + V(col 3) + V(col 4)
      return const [
        CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 2),
        CoverTileLayout(column: 3, row: 1, columnSpan: 1, rowSpan: 2),
        CoverTileLayout(column: 4, row: 1, columnSpan: 1, rowSpan: 2),
      ];
    } else {
      // [H, H, H] → H(cols 1-2, row 1) + H(cols 3-4, row 1) + H(cols 1-4, row 2)
      return const [
        CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 1),
        CoverTileLayout(column: 3, row: 1, columnSpan: 2, rowSpan: 1),
        CoverTileLayout(column: 1, row: 2, columnSpan: 4, rowSpan: 1),
      ];
    }
  }
}

/// Data model for a cover photo
class CoverPhotoData {
  final String id;
  final String imageUrl;
  final bool isPortrait;

  const CoverPhotoData({
    required this.id,
    required this.imageUrl,
    required this.isPortrait,
  });
}
