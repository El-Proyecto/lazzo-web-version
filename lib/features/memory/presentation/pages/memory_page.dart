import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/sections/cover_mosaic.dart';
import '../../../../shared/components/sections/hybrid_photo_grid.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/memory_providers.dart';
import '../../domain/entities/memory_entity.dart';

/// Memory page displaying a completed event's photos
/// Structure (top to bottom):
/// - Header: back button, "Memory" title, share button
/// - Cover Mosaic: 1-3 cover photos with adaptive layout
/// - Event title & subtitle (location • date)
/// - Photo Grid: all non-cover photos
class MemoryPage extends ConsumerWidget {
  final String memoryId;

  const MemoryPage({
    super.key,
    required this.memoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryAsync = ref.watch(memoryDetailProvider(memoryId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: 'Memory',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: memoryAsync.maybeWhen(
          data: (memory) => memory != null
              ? IconButton(
                  icon: const Icon(Icons.share, color: BrandColors.text1),
                  onPressed: () => _handleShare(context, ref),
                )
              : null,
          orElse: () => null,
        ),
      ),
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

          final coverPhotos = memory.coverPhotos;
          final gridPhotos = memory.gridPhotos;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Gaps.lg),

                // Cover Mosaic (full width with horizontal padding)
                CoverMosaic(
                  covers: coverPhotos
                      .map(
                        (photo) => CoverPhotoData(
                          id: photo.id,
                          imageUrl: photo.coverUrl ?? photo.url,
                          isPortrait: photo.isPortrait,
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: Gaps.lg),

                // Event Title & Subtitle (full width, center-aligned)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Insets.screenH),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        memory.title,
                        style: AppText.subtitleMuted.copyWith(
                          color: BrandColors.text1,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: Gaps.xxs),

                      // Subtitle: location • date
                      Text(
                        _buildSubtitle(memory.location, memory.eventDate),
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Gaps.xl),

                // Hybrid Photo Grid with Clustering
                HybridPhotoGrid(
                  clusters: _buildClusters(gridPhotos),
                ),

                const SizedBox(height: Gaps.md),
              ],
            ),
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

  /// Build subtitle text: "Location • Date"
  String _buildSubtitle(String? location, DateTime eventDate) {
    final dateStr = DateFormat('d MMMM yyyy').format(eventDate);
    if (location != null && location.isNotEmpty) {
      return '$location • $dateStr';
    }
    return dateStr;
  }

  /// Build photo clusters from grid photos
  /// Groups photos by temporal proximity (same day/hour)
  List<PhotoCluster> _buildClusters(List<MemoryPhoto> photos) {
    if (photos.isEmpty) return [];

    final clusters = <PhotoCluster>[];
    final sorted = List<MemoryPhoto>.from(photos)
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));

    var currentCluster = <MemoryPhoto>[];
    DateTime? currentDate;

    for (final photo in sorted) {
      final photoDate = DateTime(
        photo.capturedAt.year,
        photo.capturedAt.month,
        photo.capturedAt.day,
      );

      if (currentDate == null || !_isSameDay(currentDate, photoDate)) {
        // New cluster
        if (currentCluster.isNotEmpty) {
          clusters.add(PhotoCluster(
            label: _formatClusterLabel(currentDate!),
            photos: currentCluster
                .map(
                  (p) => HybridPhotoData(
                    id: p.id,
                    imageUrl: p.thumbnailUrl ?? p.url,
                    isPortrait: p.isPortrait,
                    aspectRatio: p.aspectRatio,
                    capturedAt: p.capturedAt,
                  ),
                )
                .toList(),
          ));
        }
        currentCluster = [photo];
        currentDate = photoDate;
      } else {
        currentCluster.add(photo);
      }
    }

    // Add last cluster
    if (currentCluster.isNotEmpty && currentDate != null) {
      clusters.add(PhotoCluster(
        label: _formatClusterLabel(currentDate),
        photos: currentCluster
            .map(
              (p) => HybridPhotoData(
                id: p.id,
                imageUrl: p.thumbnailUrl ?? p.url,
                isPortrait: p.isPortrait,
                aspectRatio: p.aspectRatio,
                capturedAt: p.capturedAt,
              ),
            )
            .toList(),
      ));
    }

    return clusters;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatClusterLabel(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date);
  }

  /// Handle share button press
  void _handleShare(BuildContext context, WidgetRef ref) {
    ref.read(shareMemoryProvider.notifier).share(memoryId);

    // Listen for share result
    ref.listen<AsyncValue<String?>>(
      shareMemoryProvider,
      (previous, next) {
        next.when(
          data: (shareUrl) {
            if (shareUrl != null) {
              // TODO: Trigger native share with shareUrl
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Share URL: $shareUrl'),
                  backgroundColor: BrandColors.planning,
                ),
              );
            }
          },
          loading: () {},
          error: (error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to share: $error'),
                backgroundColor: BrandColors.cantVote,
              ),
            );
          },
        );
      },
    );
  }
}
