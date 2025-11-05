// cover_mosaic.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../themes/colors.dart';

class CoverTileLayout {
  final int column; // 1..N (normalmente 1..4)
  final int row; // 1..N (passa a suportar 3 linhas nos 3H)
  final int columnSpan; // 1..4
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
  final Function(String photoId)? onPhotoTap;

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

    final visibleCovers = covers.take(3).toList(growable: false);

    // Single-Hero (mantido)
    if (visibleCovers.length == 1) {
      final cover = visibleCovers.first;
      final viewportH = MediaQuery.of(context).size.height;
      final width = MediaQuery.of(context).size.width - horizontalPadding * 2;
      final baseHeight = width / 16 * 9;
      final minH = viewportH * 0.36;
      final maxH = viewportH * 0.42;
      final height = baseHeight.clamp(minH, maxH);

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  cover.imageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  color: Colors.black.withAlpha((0.30 * 255).round()),
                  colorBlendMode: BlendMode.darken,
                  filterQuality: FilterQuality.low,
                  width: width,
                  height: height,
                ),
              ),
              if (cover.isPortrait)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 4 / 5,
                      child: FractionallySizedBox(
                        widthFactor: 0.7,
                        child: Image.network(
                          cover.imageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    cover.imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Layout normal (2 ou 3 covers), agora com as tuas regras novas
    final layouts = _calculateLayouts(visibleCovers);

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerW = constraints.maxWidth;
        final contentW = containerW - horizontalPadding * 2;
        if (contentW <= 0) return const SizedBox.shrink();

        // nº colunas efetivamente usadas
        final maxColumnUsed = layouts
            .map((l) => l.column + l.columnSpan - 1)
            .fold<int>(1, math.max);
        final columnCount = math.max(maxColumnUsed, 1);

        final colW = (contentW - gap * (columnCount - 1)) / columnCount;
        if (colW <= 0) return const SizedBox.shrink();

        // **ALTURA DINÂMICA** (suporta 3 filas p/ caso 3H com hero alto)
        final maxRowUsed =
            layouts.map((l) => l.row + l.rowSpan - 1).fold<int>(1, math.max);
        final height = colW * maxRowUsed + gap * (maxRowUsed - 1);

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

                final cw = (width * dpr).round();
                final ch = (height * dpr).round();

                return Positioned(
                  left: left,
                  top: top,
                  width: width,
                  height: height,
                  child: GestureDetector(
                    onTap:
                        onPhotoTap != null ? () => onPhotoTap!(cover.id) : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.sm),
                      child: Image.network(
                        cover.imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
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

  /// Novas regras determinísticas (até 3 covers) com "hero" conforme pedido.
  List<CoverTileLayout> _calculateLayouts(List<CoverPhotoData> covers) {
    final n = covers.length;
    final isV = covers.map((c) => c.isPortrait).toList(growable: false);
    final vCount = isV.where((v) => v).length;
    final hCount = n - vCount;

    // Helpers para devolver na mesma ordem de entrada
    List<CoverTileLayout> returnByIndex(Map<int, CoverTileLayout> m) =>
        List.generate(n, (i) => m[i]!);

    // ----------------
    // 2 covers
    // ----------------
    if (n == 2) {
      // 2H -> ambas hero (2x2 lado a lado)
      if (hCount == 2) {
        return returnByIndex({
          0: const CoverTileLayout(
              column: 1, row: 1, columnSpan: 2, rowSpan: 2),
          1: const CoverTileLayout(
              column: 3, row: 1, columnSpan: 2, rowSpan: 2),
        });
      }
      // 2V -> ambas hero (2x2 lado a lado)
      if (vCount == 2) {
        return returnByIndex({
          0: const CoverTileLayout(
              column: 1, row: 1, columnSpan: 2, rowSpan: 2),
          1: const CoverTileLayout(
              column: 3, row: 1, columnSpan: 2, rowSpan: 2),
        });
      }
      // 1V e 1H -> ambos ficam hero (2x2 lado a lado)
      if (vCount == 1 && hCount == 1) {
        return returnByIndex({
          0: const CoverTileLayout(
              column: 1, row: 1, columnSpan: 2, rowSpan: 2),
          1: const CoverTileLayout(
              column: 3, row: 1, columnSpan: 2, rowSpan: 2),
        });
      }
    }

    // ----------------
    // 3 covers
    // ----------------
    if (n == 3) {
      // 2V e 1H -> H vira hero (2x2), V's em col 3 e 4
      if (vCount == 2 && hCount == 1) {
        final hIndex = isV.indexWhere((v) => v == false);
        final vIndices = [0, 1, 2]..remove(hIndex);
        final map = <int, CoverTileLayout>{};

        map[hIndex] =
            const CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 2);
        // V's lado direito
        map[vIndices[0]] =
            const CoverTileLayout(column: 3, row: 1, columnSpan: 1, rowSpan: 2);
        map[vIndices[1]] =
            const CoverTileLayout(column: 4, row: 1, columnSpan: 1, rowSpan: 2);
        return returnByIndex(map);
      }

      // 3H -> o mais largo (o que apanha 4 colunas) ganha altura extra (rowSpan:2)
      if (hCount == 3) {
        return [
          // topo
          const CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 1),
          const CoverTileLayout(column: 3, row: 1, columnSpan: 2, rowSpan: 1),
          // largura total em baixo com mais altura (passa a ocupar fila 2 e 3)
          const CoverTileLayout(column: 1, row: 2, columnSpan: 4, rowSpan: 2),
        ];
      }

      // Outros casos 3 covers mantêm o teu comportamento anterior
      final a = isV[0], b = isV[1], c = isV[2];
      if (a && !b && !c) {
        return [
          const CoverTileLayout(column: 1, row: 1, columnSpan: 1, rowSpan: 2),
          const CoverTileLayout(column: 2, row: 1, columnSpan: 2, rowSpan: 1),
          const CoverTileLayout(column: 2, row: 2, columnSpan: 2, rowSpan: 1),
        ];
      } else if (!a && b && !c) {
        return [
          const CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 1),
          const CoverTileLayout(column: 4, row: 1, columnSpan: 1, rowSpan: 2),
          const CoverTileLayout(column: 1, row: 2, columnSpan: 2, rowSpan: 1),
        ];
      } else if (!a && !b && c) {
        return [
          const CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 1),
          const CoverTileLayout(column: 3, row: 1, columnSpan: 2, rowSpan: 1),
          const CoverTileLayout(column: 4, row: 1, columnSpan: 1, rowSpan: 2),
        ];
      } else if (a && b && !c) {
        return [
          const CoverTileLayout(column: 1, row: 1, columnSpan: 1, rowSpan: 2),
          const CoverTileLayout(column: 2, row: 1, columnSpan: 1, rowSpan: 2),
          const CoverTileLayout(column: 3, row: 2, columnSpan: 2, rowSpan: 1),
        ];
      } else if (a && b && c) {
        return [
          const CoverTileLayout(column: 1, row: 1, columnSpan: 2, rowSpan: 2),
          const CoverTileLayout(column: 3, row: 1, columnSpan: 1, rowSpan: 2),
          const CoverTileLayout(column: 4, row: 1, columnSpan: 1, rowSpan: 2),
        ];
      }
    }

    // Fallback: coluna a coluna, 1x2
    return List.generate(
      n,
      (i) => CoverTileLayout(column: 1 + i, row: 1, columnSpan: 1, rowSpan: 2),
    );
  }
}

class CoverPhotoData {
  final String id;
  final String imageUrl;
  final bool isPortrait;

  /// Novo: usado no caso "1V e 1H - a com mais votos passa a hero".
  final int votes;

  const CoverPhotoData({
    required this.id,
    required this.imageUrl,
    required this.isPortrait,
    this.votes = 0,
  });
}
