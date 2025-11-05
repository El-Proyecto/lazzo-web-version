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
/// Templates (by priority):
/// 1) L+P / P+L (L full + P)
/// 2) L½ + L½
/// 3) P + P + P
/// 4) L (full) alone [end of cluster only, except special 3L case]
class HybridPhotoGrid extends StatelessWidget {
  final List<PhotoCluster> clusters;
  final Function(String photoId)? onPhotoTap;

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
        // Visual base: padding 16, gap 8, 3 visual columns -> 6 sub-grid units.
        const padding = Insets.screenH; // 16px
        const gap = Gaps.xs; // 8px
        const subCols = 6; // 6-unit sub-grid (each visual column = 2 units)

        final screenW = constraints.maxWidth;
        final innerW = screenW - padding * 2;

        // Pixel-snapped unit width (floor), then distribute leftover equally.
        final unitW =
            ((innerW - gap * (subCols - 1)) / subCols).floorToDouble();
        final usedW = unitW * subCols + gap * (subCols - 1);
        final leftover = (innerW - usedW).clamp(0, innerW);
        final innerSidePad = leftover / 2;

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

                  // Photos in cluster (operate strictly within this cluster)
                  ..._buildClusterRows(
                      cluster.photos, unitW, gap, innerSidePad),

                  const SizedBox(height: Gaps.lg),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Build rows for a cluster using greedy priority selection.
  /// Operates only within this cluster; no cross-cluster reordering.
  List<Widget> _buildClusterRows(
    List<HybridPhotoData> photos,
    double unitW,
    double gap,
    double innerSidePad,
  ) {
    final rows = <Widget>[];
    final buffer = List<HybridPhotoData>.from(photos);

    while (buffer.isNotEmpty) {
      final rowResult = _selectBestTemplate(buffer, unitW, gap, innerSidePad);
      rows.add(rowResult.widget);

      // Remove ONLY the used indexes (descending order to keep indices valid).
      final idxs = rowResult.usedIndexes.toList()..sort();
      for (int k = idxs.length - 1; k >= 0; k--) {
        buffer.removeAt(idxs[k]);
      }
    }

    return rows;
  }

  /// Select the best row template for the current buffer with lookahead ≤ 4.
  _TemplateResult _selectBestTemplate(
    List<HybridPhotoData> buffer,
    double unitW,
    double gap,
    double innerSidePad,
  ) {
    final la = math.min(4, buffer.length);
    final cand = buffer.take(la).toList(growable: false);

    bool isP(int i) => cand[i].isPortrait;
    bool isL(int i) => !cand[i].isPortrait;

    // ---- Priority 1: L full + P (or P + L full) ----
    // (a) L then P anywhere within lookahead
    for (int i = 0; i < la - 1; i++) {
      if (isL(i)) {
        for (int j = i + 1; j < la; j++) {
          if (isP(j)) {
            return _TemplateResult(
              widget: Padding(
                padding: EdgeInsets.symmetric(horizontal: innerSidePad),
                child: _buildRowLPlusP([cand[i], cand[j]], unitW, gap),
              ),
              usedIndexes: [i, j],
              penalty: 0,
            );
          }
        }
        break; // found first L but no P after in lookahead
      }
    }
    // (b) P then L anywhere within lookahead
    for (int i = 0; i < la - 1; i++) {
      if (isP(i)) {
        for (int j = i + 1; j < la; j++) {
          if (isL(j)) {
            return _TemplateResult(
              widget: Padding(
                padding: EdgeInsets.symmetric(horizontal: innerSidePad),
                child: _buildRowPPlusL([cand[i], cand[j]], unitW, gap),
              ),
              usedIndexes: [i, j],
              penalty: 0,
            );
          }
        }
        break; // found first P but no L after in lookahead
      }
    }

    // ---- Priority 2: L½ + L½ ----
    // Two consecutive L before the first P in lookahead.
    int firstP = cand.indexWhere((e) => e.isPortrait);
    if (firstP == -1) firstP = la; // no P in lookahead
    for (int i = 0; i < math.min(firstP - 1, la - 1); i++) {
      if (isL(i) && isL(i + 1)) {
        return _TemplateResult(
          widget: Padding(
            padding: EdgeInsets.symmetric(horizontal: innerSidePad),
            child: _buildRowLhalfLhalf([cand[i], cand[i + 1]], unitW, gap),
          ),
          usedIndexes: [i, i + 1],
          penalty: 0,
        );
      }
    }

    // ---- Priority 3: P + P + P (must use the first three items if all P) ----
    if (buffer.length >= 3 && isP(0) && isP(1) && isP(2)) {
      return _TemplateResult(
        widget: Padding(
          padding: EdgeInsets.symmetric(horizontal: innerSidePad),
          child: _buildRowPPP([cand[0], cand[1], cand[2]], unitW, gap),
        ),
        usedIndexes: const [0, 1, 2],
        penalty: 0,
      );
    }

    // ---- Priority 4: L full alone ----
    // Only at end of cluster OR special case of exactly one item left.
    if (buffer.length == 1 && isL(0)) {
      return _TemplateResult(
        widget: Padding(
          padding: EdgeInsets.symmetric(horizontal: innerSidePad),
          child: _buildRowLAlone(cand[0], unitW, gap),
        ),
        usedIndexes: const [0],
        penalty: 0,
      );
    }

    // ---- Fallbacks (safety) ----
    if (isP(0)) {
      return _TemplateResult(
        widget: Padding(
          padding: EdgeInsets.symmetric(horizontal: innerSidePad),
          child: _buildRowPSingle(cand[0], unitW, gap),
        ),
        usedIndexes: const [0],
        penalty: 0,
      );
    } else {
      // Single landscape not at end → still allow full to keep flow (soft relax).
      return _TemplateResult(
        widget: Padding(
          padding: EdgeInsets.symmetric(horizontal: innerSidePad),
          child: _buildRowLAlone(cand[0], unitW, gap),
        ),
        usedIndexes: const [0],
        penalty: 0,
      );
    }
  }

  // ---------- ROW BUILDERS (all enforce a single rowHeight) ----------

  /// Row: L full + P
  Widget _buildRowLPlusP(
      List<HybridPhotoData> photos, double unitW, double gap) {
    final wL = unitW * 4 + gap * 3; // span 4 units -> adds 3 inner gaps
    final wP = unitW * 2 + gap; // span 2 units -> adds 1 inner gap
    final hL = wL * 9 / 16;
    final hP = wP * 5 / 4;
    final rowH = math.max(hL, hP);

    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.xs),
      child: Row(
        children: [
          _buildPhotoTile(photos[0], wL, hL, rowHeight: rowH),
          SizedBox(width: gap),
          _buildPhotoTile(photos[1], wP, hP, rowHeight: rowH),
        ],
      ),
    );
  }

  /// Row: P + L full
  Widget _buildRowPPlusL(
      List<HybridPhotoData> photos, double unitW, double gap) {
    final wL = unitW * 4 + gap * 3;
    final wP = unitW * 2 + gap;
    final hL = wL * 9 / 16;
    final hP = wP * 5 / 4;
    final rowH = math.max(hL, hP);

    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.xs),
      child: Row(
        children: [
          _buildPhotoTile(photos[0], wP, hP, rowHeight: rowH),
          SizedBox(width: gap),
          _buildPhotoTile(photos[1], wL, hL, rowHeight: rowH),
        ],
      ),
    );
  }

  /// Row: L½ + L½ (pair only)
  Widget _buildRowLhalfLhalf(
      List<HybridPhotoData> photos, double unitW, double gap) {
    final wHalf = unitW * 3 + gap * 2; // span 3 units -> adds 2 inner gaps
    final h = wHalf * 9 / 16; // 16:9
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.xs),
      child: Row(
        children: [
          _buildPhotoTile(photos[0], wHalf, h, rowHeight: h),
          SizedBox(width: gap),
          _buildPhotoTile(photos[1], wHalf, h, rowHeight: h),
        ],
      ),
    );
  }

  /// Row: P + P + P
  Widget _buildRowPPP(List<HybridPhotoData> photos, double unitW, double gap) {
    final wP = unitW * 2 + gap;
    final h = wP * 5 / 4; // 4:5
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.xs),
      child: Row(
        children: [
          _buildPhotoTile(photos[0], wP, h, rowHeight: h),
          SizedBox(width: gap),
          _buildPhotoTile(photos[1], wP, h, rowHeight: h),
          SizedBox(width: gap),
          _buildPhotoTile(photos[2], wP, h, rowHeight: h),
        ],
      ),
    );
  }

  /// Row: L full alone (left-aligned)
  Widget _buildRowLAlone(HybridPhotoData photo, double unitW, double gap) {
    final wL = unitW * 4 + gap * 3;
    final h = wL * 9 / 16;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildPhotoTile(photo, wL, h, rowHeight: h),
        ],
      ),
    );
  }

  /// Row: single P (fallback safety)
  Widget _buildRowPSingle(HybridPhotoData photo, double unitW, double gap) {
    final wP = unitW * 2 + gap;
    final h = wP * 5 / 4;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPhotoTile(photo, wP, h, rowHeight: h),
        ],
      ),
    );
  }

  // ---------- TILE BUILDER ----------

  /// Builds a single photo tile clipped and center-cropped.
  /// width/height are the "natural" AR sizes; rowHeight enforces equal height in the row.
  Widget _buildPhotoTile(
    HybridPhotoData photo,
    double width,
    double height, {
    double? rowHeight,
  }) {
    final targetHeight = rowHeight ?? height;

    return GestureDetector(
      onTap: onPhotoTap != null ? () => onPhotoTap!(photo.id) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: targetHeight, // same height for all tiles in row
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.sm),
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center,
            child: SizedBox(
              width: width,
              height: height, // maintained AR inside the FittedBox
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
  final List<int> usedIndexes; // indexes in current lookahead/buffer prefix
  final int penalty;

  const _TemplateResult({
    required this.widget,
    required this.usedIndexes,
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
