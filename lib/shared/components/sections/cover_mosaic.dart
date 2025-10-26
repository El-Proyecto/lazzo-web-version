// cover_mosaic.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../themes/colors.dart';

class CoverTileLayout {
  final int column; // 1..4
  final int row; // 1..2
  final int columnSpan; // 1..4 (regra prática: 1..2, exceto HHH -> 4)
  final int rowSpan; // 1..2
  const CoverTileLayout({
    required this.column,
    required this.row,
    required this.columnSpan,
    required this.rowSpan,
  });
}

class CoverMosaic extends StatelessWidget {
  final List<CoverPhotoData> covers;

  /// Horizontal padding around the mosaic; defaults to screen gutters.
  final double horizontalPadding;

  /// Gap between tiles; defaults to spacing token.
  final double gap;

  /// Tap handler for any tile.
  final VoidCallback? onPhotoTap;

  const CoverMosaic({
    super.key,
    required this.covers,
    this.onPhotoTap,
    this.horizontalPadding = Insets.screenH,
    this.gap = Gaps.xs,
  });

  @override
  Widget build(BuildContext context) {
    if (covers.isEmpty) return const SizedBox.shrink();

    // **Mostra no máximo 3 covers** (spec).
    final visibleCovers = covers.take(3).toList(growable: false);
    final layouts = _calculateLayouts(visibleCovers);

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerW = constraints.maxWidth;
        final contentW = containerW - horizontalPadding * 2;
        if (contentW <= 0) {
          return const SizedBox.shrink();
        }

        final maxColumnUsed = layouts
            .map((layout) => layout.column + layout.columnSpan - 1)
            .fold<int>(1, math.max);
        final columnCount = math.max(maxColumnUsed, 1);

        final colW = (contentW - gap * (columnCount - 1)) / columnCount;
        if (colW <= 0) {
          return const SizedBox.shrink();
        }

        // Altura fixa 2 linhas de células quadradas + 1 gap vertical (spec).
        final height = colW * 2 + gap;

        final dpr = MediaQuery.of(context).devicePixelRatio;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: SizedBox(
            width: contentW,
            height: height,
            child: Stack(
              children: List.generate(visibleCovers.length, (index) {
                final cover = visibleCovers[index];
                final layout = layouts[index];

                final width =
                    colW * layout.columnSpan + (layout.columnSpan - 1) * gap;
                final height =
                    colW * layout.rowSpan + (layout.rowSpan - 1) * gap;
                final left = (layout.column - 1) * (colW + gap);
                final top = (layout.row - 1) * (colW + gap);

                // Sugestão perf: pedir aproximadamente o tamanho de apresentação × dpr
                final cw = (width * dpr).round();
                final ch = (height * dpr).round();

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
                        fit: BoxFit.cover, // center-crop (spec 2.2)
                        alignment: Alignment.center,
                        // Se o teu CDN/Supabase suportar transform, estes hint params ajudam o cache.
                        cacheWidth: cw > 0 ? cw : 1,
                        cacheHeight: ch > 0 ? ch : 1,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: BrandColors.bg3,
                            alignment: Alignment.center,
                            child:
                                const CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                        errorBuilder: (context, _, __) {
                          return Container(
                            color: BrandColors.bg3,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image,
                                color: BrandColors.text2),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  /// Regras determinísticas de colocação (até 3 covers) — ver spec 2.3.
  List<CoverTileLayout> _calculateLayouts(List<CoverPhotoData> covers) {
    final count = covers.length.clamp(1, 3);
    final orientations = covers.take(count).map((c) => c.isPortrait).toList();

    if (count == 1) {
      return const [
        CoverTileLayout(column: 2, row: 1, columnSpan: 2, rowSpan: 2)
      ]; // B centrado
    }

    if (count == 2) {
      final v1 = orientations[0], v2 = orientations[1];
      if (v1 && !v2) {
        return const [
          CoverTileLayout(column: 1, row: 1, columnSpan: 1, rowSpan: 2), // V
          CoverTileLayout(column: 2, row: 1, columnSpan: 2, rowSpan: 1), // H
        ];
      } else if (!v1 && v2) {
        return const [
          CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 1), // H
          CoverTileLayout(column: 4, row: 1, columnSpan: 1, rowSpan: 2), // V
        ];
      } else if (v1 && v2) {
        return const [
          CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 2), // B
          CoverTileLayout(column: 4, row: 1, columnSpan: 1, rowSpan: 2), // V
        ];
      } else {
        return const [
          CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 1), // H
          CoverTileLayout(column: 3, row: 1, columnSpan: 2, rowSpan: 1), // H
        ];
      }
    }

    // count == 3
    final v1 = orientations[0], v2 = orientations[1], v3 = orientations[2];
    if (v1 && !v2 && !v3) {
      return const [
        CoverTileLayout(column: 1, row: 1, columnSpan: 1, rowSpan: 2), // V
        CoverTileLayout(column: 2, row: 1, columnSpan: 2, rowSpan: 1), // H
        CoverTileLayout(column: 2, row: 2, columnSpan: 2, rowSpan: 1), // H
      ];
    } else if (!v1 && v2 && !v3) {
      return const [
        CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 1), // H
        CoverTileLayout(column: 4, row: 1, columnSpan: 1, rowSpan: 2), // V
        CoverTileLayout(column: 1, row: 2, columnSpan: 2, rowSpan: 1), // H
      ];
    } else if (!v1 && !v2 && v3) {
      return const [
        CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 1), // H
        CoverTileLayout(column: 3, row: 1, columnSpan: 2, rowSpan: 1), // H
        CoverTileLayout(column: 4, row: 1, columnSpan: 1, rowSpan: 2), // V
      ];
    } else if (v1 && v2 && !v3) {
      return const [
        CoverTileLayout(column: 1, row: 1, columnSpan: 1, rowSpan: 2), // V
        CoverTileLayout(column: 2, row: 1, columnSpan: 1, rowSpan: 2), // V
        CoverTileLayout(column: 3, row: 2, columnSpan: 2, rowSpan: 1), // H
      ];
    } else if (v1 && v2 && v3) {
      return const [
        CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 2), // B
        CoverTileLayout(column: 3, row: 1, columnSpan: 1, rowSpan: 2), // V
        CoverTileLayout(column: 4, row: 1, columnSpan: 1, rowSpan: 2), // V
      ];
    } else {
      // H, H, H
      return const [
        CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 1), // H
        CoverTileLayout(column: 3, row: 1, columnSpan: 2, rowSpan: 1), // H
        CoverTileLayout(
            column: 1,
            row: 2,
            columnSpan: 4,
            rowSpan: 1), // H (spana 4 colunas)
      ];
    }
  }
}

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
