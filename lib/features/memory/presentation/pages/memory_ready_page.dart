import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/sections/cover_mosaic.dart';
import '../../../../shared/components/sections/hybrid_photo_grid.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../home/presentation/providers/home_event_providers.dart';
import '../providers/memory_providers.dart';
import '../../domain/entities/memory_entity.dart';
import '../../../../services/analytics_service.dart';

/// Memory Ready page shown at the end of recap phase
/// NO SCROLL - fixed height layout
/// Structure (top to bottom):
/// - Header: close button only (like GroupCreatedPage)
/// - Title: 🎉 Your Memory is ready + event name
/// - Cover Mosaic: same as memory page but no tap action
/// - Photo Grid Preview: 1st row from hybrid grid (no clustering labels)
/// - Action Buttons: Share (recap orange) + Open (bg2)
class MemoryReadyPage extends ConsumerStatefulWidget {
  final String memoryId;

  const MemoryReadyPage({
    super.key,
    required this.memoryId,
  });

  @override
  ConsumerState<MemoryReadyPage> createState() => _MemoryReadyPageState();
}

class _MemoryReadyPageState extends ConsumerState<MemoryReadyPage> {
  bool _hasTrackedMemoryReady = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.screenViewed('memory_ready', eventId: widget.memoryId);
  }

  /// Track the memory_ready custom event once when memory data loads.
  /// Properties: photo_count, contributor_count, hours_since_event_end.
  void _trackMemoryReadyEvent(MemoryEntity memory) {
    if (_hasTrackedMemoryReady) return;
    _hasTrackedMemoryReady = true;

    // Unique uploaders = contributors
    final contributorCount =
        memory.photos.map((p) => p.uploaderId).toSet().length;

    // Hours since event end (null-safe)
    double? hoursSinceEnd;
    if (memory.endDatetime != null) {
      hoursSinceEnd =
          DateTime.now().difference(memory.endDatetime!).inMinutes / 60.0;
    }

    AnalyticsService.track('memory_ready', properties: {
      'event_id': widget.memoryId,
      'photo_count': memory.photos.length,
      'contributor_count': contributorCount,
      if (hoursSinceEnd != null)
        'hours_since_event_end': double.parse(hoursSinceEnd.toStringAsFixed(1)),
      'platform': 'ios',
    });
  }

  @override
  Widget build(BuildContext context) {
    final memoryAsync = ref.watch(memoryDetailProvider(widget.memoryId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: _buildAppBar(context, ref),
      body: memoryAsync.when(
        data: (memory) {
          if (memory == null) {
            return const Center(
              child: Text(
                'Memory not found',
                style: TextStyle(color: BrandColors.text2),
              ),
            );
          }

          // Track memory_ready event with photo/contributor stats
          _trackMemoryReadyEvent(memory);

          return _MemoryReadyContent(
            memory: memory,
            memoryId: widget.memoryId,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Insets.screenH),
            child: Text(
              'Error loading memory: $error',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// Build AppBar with only close button (like GroupCreatedPage)
  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return CommonAppBar(
      title: '',
      trailing: IconButton(
        icon: const Icon(Icons.close, color: BrandColors.text1),
        onPressed: () {
          // Refresh home data before navigating back
          ref.invalidate(nextEventControllerProvider);
          ref.invalidate(confirmedEventsControllerProvider);
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.mainLayout,
            (route) => false,
          );
        },
      ),
    );
  }
}

/// Content widget - NO SCROLL, fixed layout
class _MemoryReadyContent extends StatelessWidget {
  final MemoryEntity memory;
  final String memoryId;

  const _MemoryReadyContent({
    required this.memory,
    required this.memoryId,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final availableHeight = screenHeight - appBarHeight;

    final coverPhotos = memory.coverPhotos;
    final gridPhotos = memory.gridPhotos;

    return SizedBox(
      height: availableHeight,
      child: Column(
        children: [
          const SizedBox(height: Gaps.sm),

          // Title + Subtitle at the top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
            child: Column(
              children: [
                // Title with emoji
                Text(
                  '🎉 Your Memory is ready',
                  style: AppText.dropdownTitle.copyWith(
                    color: BrandColors.text1,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: Gaps.xs),

                // Subtitle: event name
                Text(
                  memory.title,
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: Gaps.md),

          // Cover Mosaic - same as memory page but no tap
          Flexible(
            flex: 5,
            child: CoverMosaic(
              covers: coverPhotos
                  .map(
                    (photo) => CoverPhotoData(
                      id: photo.id,
                      imageUrl: photo.coverUrl ?? photo.url,
                      isPortrait: photo.isPortrait,
                    ),
                  )
                  .toList(),
              onPhotoTap: null, // No tap action on ready page
            ),
          ),

          const SizedBox(height: Gaps.xs),

          // Photo Grid Preview (1st row, like memory page)
          // Wrapped in Flexible to prevent overflow on small screens
          if (gridPhotos.isNotEmpty)
            Flexible(
              flex: 3,
              child: _PhotoGridPreview(photos: gridPhotos),
            ),

          const Spacer(),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
            child: Column(
              children: [
                // Share Memory button (recap orange)
                _ShareMemoryButton(memoryId: memoryId),

                const SizedBox(height: Gaps.sm),

                // Open Memory button (bg2)
                _OpenMemoryButton(memoryId: memoryId),
              ],
            ),
          ),

          SizedBox(height: Gaps.lg + bottomPadding),
        ],
      ),
    );
  }
}

/// Photo Grid Preview - shows only 1 row without clustering labels
class _PhotoGridPreview extends StatelessWidget {
  final List<MemoryPhoto> photos;

  const _PhotoGridPreview({
    required this.photos,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();

    // Take first 3 photos (enough for 1 row max)
    final previewPhotos = photos.take(3).toList();

    const padding = Insets.screenH;
    const gap = Gaps.xs;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: padding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rowWidth = constraints.maxWidth;

          // Convert to HybridPhotoData
          final hybridPhotos = previewPhotos
              .map(
                (p) => HybridPhotoData(
                  id: p.id,
                  imageUrl: p.thumbnailUrl ?? p.url,
                  isPortrait: p.isPortrait,
                  aspectRatio: p.aspectRatio,
                  capturedAt: p.capturedAt,
                ),
              )
              .toList();

          // Build single row using the full width
          return _buildPreviewRow(hybridPhotos, rowWidth, gap);
        },
      ),
    );
  }

  /// Build preview row (only 1 row, full width)
  Widget _buildPreviewRow(
    List<HybridPhotoData> photos,
    double rowWidth,
    double gap,
  ) {
    if (photos.isEmpty) return const SizedBox.shrink();

    if (photos.length >= 3 &&
        photos[0].isPortrait &&
        photos[1].isPortrait &&
        photos[2].isPortrait) {
      return _buildPPPRow(
        [photos[0], photos[1], photos[2]],
        rowWidth,
        gap,
      );
    }

    if (photos.length >= 2) {
      final first = photos[0];
      final second = photos[1];

      // L+P or P+L pattern
      if ((!first.isPortrait && second.isPortrait) ||
          (first.isPortrait && !second.isPortrait)) {
        return _buildLPRow([first, second], rowWidth, gap);
      }

      // L+L pattern
      if (!first.isPortrait && !second.isPortrait) {
        return _buildLLRow([first, second], rowWidth, gap);
      }
    }

    // Single photo (L full width or P centered)
    return _buildSingleRow(photos[0], rowWidth, gap);
  }

  /// Build P+P+P row (3 equal tiles, full width)
  Widget _buildPPPRow(
    List<HybridPhotoData> photos,
    double rowWidth,
    double gap,
  ) {
    final tileW = (rowWidth - 2 * gap) / 3;
    final tileH = tileW / 0.8;

    return Row(
      children: [
        _buildPhotoTile(photos[0], tileW, tileH),
        SizedBox(width: gap),
        _buildPhotoTile(photos[1], tileW, tileH),
        SizedBox(width: gap),
        _buildPhotoTile(photos[2], tileW, tileH),
      ],
    );
  }

  /// Build L+P or P+L row (2:1 ratio, full width)
  Widget _buildLPRow(
    List<HybridPhotoData> photos,
    double rowWidth,
    double gap,
  ) {
    final available = rowWidth - gap;
    final pTileW = available / 3; // 1/3
    final lTileW = available * 2 / 3; // 2/3
    final tileH = pTileW / 0.8;

    final landscape = photos.firstWhere((p) => !p.isPortrait);
    final portrait = photos.firstWhere((p) => p.isPortrait);
    final leadingIsLandscape = !photos[0].isPortrait;

    return Row(
      children: leadingIsLandscape
          ? [
              _buildPhotoTile(landscape, lTileW, tileH),
              SizedBox(width: gap),
              _buildPhotoTile(portrait, pTileW, tileH),
            ]
          : [
              _buildPhotoTile(portrait, pTileW, tileH),
              SizedBox(width: gap),
              _buildPhotoTile(landscape, lTileW, tileH),
            ],
    );
  }

  /// Build L+L row (2 equal tiles, full width)
  Widget _buildLLRow(
    List<HybridPhotoData> photos,
    double rowWidth,
    double gap,
  ) {
    final tileW = (rowWidth - gap) / 2;
    final tileH = tileW / 1.78;

    return Row(
      children: [
        _buildPhotoTile(photos[0], tileW, tileH),
        SizedBox(width: gap),
        _buildPhotoTile(photos[1], tileW, tileH),
      ],
    );
  }

  /// Build single photo row (L = full, P = centered 1/3)
  Widget _buildSingleRow(
    HybridPhotoData photo,
    double rowWidth,
    double gap,
  ) {
    if (!photo.isPortrait) {
      // Landscape - full width
      final tileW = rowWidth;
      final tileH = tileW / 1.78;

      return _buildPhotoTile(photo, tileW, tileH);
    } else {
      // Portrait centered at ~1/3 width
      final tileW = rowWidth / 3;
      final tileH = tileW / 0.8;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPhotoTile(photo, tileW, tileH),
        ],
      );
    }
  }

  /// Build photo tile (no tap action)
  Widget _buildPhotoTile(HybridPhotoData photo, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Image.network(
        photo.imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      ),
    );
  }
}

/// Share Memory button (text color text1, background recap orange)
class _ShareMemoryButton extends StatelessWidget {
  final String memoryId;

  const _ShareMemoryButton({
    required this.memoryId,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _navigateToShareMemory(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.recap,
          foregroundColor: BrandColors.text1,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
        child: Text(
          'Share memory',
          style: AppText.labelLarge.copyWith(
            color: BrandColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _navigateToShareMemory(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRouter.shareMemory,
      arguments: {'memoryId': memoryId},
    );
  }
}

/// Open Memory button (bg2 background)
class _OpenMemoryButton extends StatelessWidget {
  final String memoryId;

  const _OpenMemoryButton({
    required this.memoryId,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _navigateToMemory(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.bg2,
          foregroundColor: BrandColors.text1,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
        child: Text(
          'Open memory',
          style: AppText.labelLarge.copyWith(
            color: BrandColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _navigateToMemory(BuildContext context) {
    // Use pushNamed to keep MainLayout in navigation stack
    // This ensures back button returns to Home instead of empty page
    Navigator.of(context).pushNamed(
      AppRouter.memory,
      arguments: {'memoryId': memoryId, 'viewSource': 'memory_ready'},
    );
  }
}
