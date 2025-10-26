import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Photo cluster for temporal grouping
class PhotoCluster {
  final String label; // e.g., "Morning", "5 July 2024"
  final List<HybridPhotoData> photos;

  const PhotoCluster({
    required this.label,
    required this.photos,
  });
}

/// Hybrid mosaic grid with row templates and temporal clustering
/// Templates: PPP, LspanP, PLspan, LspanLspan
class HybridPhotoGrid extends StatelessWidget {
  final List<PhotoCluster> clusters;
  final VoidCallback? onPhotoTap;

  const HybridPhotoGrid({
    super.key,
    required this.clusters,
    this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    if (clusters.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = Insets.screenH; // 16px
        const gap = Gaps.xs; // 8px
        const columns = 3;

        final screenW = constraints.maxWidth;
        final colW = (screenW - padding * 2 - gap * 2) / columns;
        final showClusterLabels = clusters.length > 1;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: clusters.map((cluster) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showClusterLabels)
                    Container(
                      margin: const EdgeInsets.only(bottom: Gaps.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Pads.ctlH,
                        vertical: Pads.ctlVXss,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.bg2,
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                      child: Text(
                        cluster.label,
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                        ),
                      ),
                    ),

                  // Photos in cluster
                  ..._buildClusterRows(cluster.photos, colW, gap),

                  const SizedBox(height: Gaps.lg),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Build rows for a cluster using greedy template matching
  List<Widget> _buildClusterRows(
    List<HybridPhotoData> photos,
    double colW,
    double gap,
  ) {
    final rows = <Widget>[];
    final buffer = List<HybridPhotoData>.from(photos);

    while (buffer.isNotEmpty) {
      final rowResult = _selectBestTemplate(buffer, colW, gap);
      rows.add(rowResult.widget);
      buffer.removeRange(0, rowResult.photosUsed);
    }

    return rows;
  }

  /// Select best template for current buffer using greedy algorithm
  _TemplateResult _selectBestTemplate(
    List<HybridPhotoData> buffer,
    double colW,
    double gap,
  ) {
    final lookAhead = buffer.length > 5 ? 5 : buffer.length;
    final candidates = buffer.take(lookAhead).toList();

    // Try all templates and calculate penalty
    final templates = <_TemplateResult>[];

    // Template 1: P P P (3 portraits)
    if (candidates.length >= 3 &&
        candidates[0].isPortrait &&
        candidates[1].isPortrait &&
        candidates[2].isPortrait) {
      final penalty = _calculatePenalty(
          [candidates[0], candidates[1], candidates[2]], 0, 0, 0);
      templates.add(_TemplateResult(
        widget: _buildPPPRow(
            [candidates[0], candidates[1], candidates[2]], colW, gap),
        photosUsed: 3,
        penalty: penalty,
      ));
    }

    // Template 2: Lspan P (landscape + portrait)
    if (candidates.length >= 2) {
      for (var i = 0; i < lookAhead - 1; i++) {
        if (!candidates[i].isPortrait && candidates[i + 1].isPortrait) {
          final reorderIndex = i;
          final breakMismatch = _aspectRatioMismatch(candidates[i], false) +
              _aspectRatioMismatch(candidates[i + 1], true);
          final orphan = _orphanPenalty(buffer, i + 2);
          final penalty = _calculatePenalty(
            [candidates[i], candidates[i + 1]],
            reorderIndex,
            breakMismatch,
            orphan,
          );

          if (reorderIndex <= 3) {
            templates.add(_TemplateResult(
              widget: _buildLspanPRow(
                  [candidates[i], candidates[i + 1]], colW, gap),
              photosUsed: i + 2,
              penalty: penalty,
            ));
          }
        }
      }
    }

    // Template 3: P Lspan (portrait + landscape)
    if (candidates.length >= 2) {
      for (var i = 0; i < lookAhead - 1; i++) {
        if (candidates[i].isPortrait && !candidates[i + 1].isPortrait) {
          final reorderIndex = i;
          final breakMismatch = _aspectRatioMismatch(candidates[i], true) +
              _aspectRatioMismatch(candidates[i + 1], false);
          final orphan = _orphanPenalty(buffer, i + 2);
          final penalty = _calculatePenalty(
            [candidates[i], candidates[i + 1]],
            reorderIndex,
            breakMismatch,
            orphan,
          );

          if (reorderIndex <= 3) {
            templates.add(_TemplateResult(
              widget: _buildPLspanRow(
                  [candidates[i], candidates[i + 1]], colW, gap),
              photosUsed: i + 2,
              penalty: penalty,
            ));
          }
        }
      }
    }

    // Template 4: Lspan Lspan (two landscapes, double height if consecutive)
    if (candidates.length >= 2) {
      for (var i = 0; i < lookAhead - 1; i++) {
        if (!candidates[i].isPortrait && !candidates[i + 1].isPortrait) {
          final reorderIndex = i;
          final breakMismatch = _aspectRatioMismatch(candidates[i], false) +
              _aspectRatioMismatch(candidates[i + 1], false);
          final orphan = _orphanPenalty(buffer, i + 2);
          final penalty = _calculatePenalty(
            [candidates[i], candidates[i + 1]],
            reorderIndex,
            breakMismatch,
            orphan,
          );

          if (reorderIndex <= 3) {
            templates.add(_TemplateResult(
              widget: _buildLspanLspanRow(
                  [candidates[i], candidates[i + 1]], colW, gap),
              photosUsed: i + 2,
              penalty: penalty,
            ));
          }
        }
      }
    }

    // Fallback: single portrait or landscape
    if (templates.isEmpty) {
      if (candidates[0].isPortrait) {
        return _TemplateResult(
          widget: _buildSinglePRow(candidates[0], colW, gap),
          photosUsed: 1,
          penalty: 0,
        );
      } else {
        return _TemplateResult(
          widget: _buildSingleLRow(candidates[0], colW, gap),
          photosUsed: 1,
          penalty: 0,
        );
      }
    }

    // Select template with lowest penalty
    templates.sort((a, b) => a.penalty.compareTo(b.penalty));
    return templates.first;
  }

  /// Calculate penalty for a template
  int _calculatePenalty(
    List<HybridPhotoData> photos,
    int reorderIndex,
    int breakMismatch,
    int orphan,
  ) {
    return reorderIndex + breakMismatch + orphan;
  }

  /// Penalty for aspect ratio mismatch (crop quality)
  int _aspectRatioMismatch(HybridPhotoData photo, bool expectPortrait) {
    final ar = photo.aspectRatio;
    if (expectPortrait && (ar < 0.6 || ar > 1.0)) return 2;
    if (!expectPortrait && (ar < 1.2 || ar > 2.0)) return 2;
    return 0;
  }

  /// Penalty for leaving orphan landscape
  int _orphanPenalty(List<HybridPhotoData> buffer, int usedCount) {
    if (usedCount >= buffer.length) return 0;
    final remaining = buffer.skip(usedCount).toList();
    if (remaining.length == 1 && !remaining[0].isPortrait) return 3;
    return 0;
  }

  /// Build P P P row (3 portraits)
  Widget _buildPPPRow(List<HybridPhotoData> photos, double colW, double gap) {
    final height = colW * 5 / 4; // 4:5
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: photos.map((photo) {
          return Padding(
            padding: EdgeInsets.only(right: photo == photos.last ? 0 : gap),
            child: _buildPhotoTile(
              photo,
              colW,
              height,
              rowHeight: height,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build Lspan P row (landscape + portrait)
  Widget _buildLspanPRow(
      List<HybridPhotoData> photos, double colW, double gap) {
    final lWidth = colW * 2 + gap;
    final lHeight = lWidth * 9 / 16; // 16:9
    final pHeight = colW * 5 / 4; // 4:5
    final rowHeight = math.max(lHeight, pHeight);

    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPhotoTile(
            photos[0],
            lWidth,
            lHeight,
            rowHeight: rowHeight,
          ),
          SizedBox(width: gap),
          _buildPhotoTile(
            photos[1],
            colW,
            pHeight,
            rowHeight: rowHeight,
          ),
        ],
      ),
    );
  }

  /// Build P Lspan row (portrait + landscape)
  Widget _buildPLspanRow(
      List<HybridPhotoData> photos, double colW, double gap) {
    final lWidth = colW * 2 + gap;
    final lHeight = lWidth * 9 / 16; // 16:9
    final pHeight = colW * 5 / 4; // 4:5
    final rowHeight = math.max(lHeight, pHeight);

    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPhotoTile(
            photos[0],
            colW,
            pHeight,
            rowHeight: rowHeight,
          ),
          SizedBox(width: gap),
          _buildPhotoTile(
            photos[1],
            lWidth,
            lHeight,
            rowHeight: rowHeight,
          ),
        ],
      ),
    );
  }

  /// Build Lspan Lspan row (two landscapes stacked)
  Widget _buildLspanLspanRow(
      List<HybridPhotoData> photos, double colW, double gap) {
    final lWidth = colW * 2 + gap;
    final lHeight = lWidth * 9 / 16; // 16:9

    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.xs),
      child: Column(
        children: [
          _buildPhotoTile(photos[0], lWidth, lHeight),
          SizedBox(height: gap),
          _buildPhotoTile(photos[1], lWidth, lHeight),
        ],
      ),
    );
  }

  /// Build single portrait row (centered)
  Widget _buildSinglePRow(HybridPhotoData photo, double colW, double gap) {
    final height = colW * 5 / 4; // 4:5
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.xs),
      child: Center(
        child: _buildPhotoTile(
          photo,
          colW,
          height,
          rowHeight: height,
        ),
      ),
    );
  }

  /// Build single landscape row (centered)
  Widget _buildSingleLRow(HybridPhotoData photo, double colW, double gap) {
    final lWidth = colW * 2 + gap;
    final lHeight = lWidth * 9 / 16; // 16:9
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.xs),
      child: Center(
        child: _buildPhotoTile(
          photo,
          lWidth,
          lHeight,
          rowHeight: lHeight,
        ),
      ),
    );
  }

  /// Build a single photo tile
  Widget _buildPhotoTile(
    HybridPhotoData photo,
    double width,
    double height, {
    double? rowHeight,
  }) {
    final targetHeight = rowHeight ?? height;

    return GestureDetector(
      onTap: onPhotoTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: targetHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.sm),
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center,
            child: SizedBox(
              width: width,
              height: height,
              child: Image.network(
                photo.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: BrandColors.bg2,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: BrandColors.bg2,
                    child: const Icon(
                      Icons.broken_image,
                      color: BrandColors.text2,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Template selection result
class _TemplateResult {
  final Widget widget;
  final int photosUsed;
  final int penalty;

  const _TemplateResult({
    required this.widget,
    required this.photosUsed,
    required this.penalty,
  });
}

/// Data model for a photo in the hybrid grid
class HybridPhotoData {
  final String id;
  final String imageUrl;
  final bool isPortrait;
  final double aspectRatio;
  final DateTime capturedAt;

  const HybridPhotoData({
    required this.id,
    required this.imageUrl,
    required this.isPortrait,
    required this.aspectRatio,
    required this.capturedAt,
  });
}
