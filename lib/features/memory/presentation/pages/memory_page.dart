import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/nav/app_bar_with_subtitle.dart';
import '../../../../shared/components/cards/add_photos_cta_card.dart';
import '../../../../shared/components/sections/cover_mosaic.dart';
import '../../../../shared/components/sections/hybrid_photo_grid.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/memory_providers.dart';
import '../../domain/entities/memory_entity.dart';
import '../../data/fakes/fake_memory_repository.dart';

/// Memory page displaying event photos with state-based UI
/// Structure (top to bottom):
/// - Header: back button, "Memory" title, edit button (conditional)
/// - CTA banner: Add photos prompt (living/recap, conditional)
/// - Cover Mosaic: 1-3 cover photos with adaptive layout
/// - Event title & subtitle (location • date)
/// - Photo Grid: all non-cover photos
///
/// Three states based on event status:
/// 1. Living: CTA banner if no photos uploaded, edit button if has photos or is host
/// 2. Recap: Same as living but with orange CTA button
/// 3. Ended: No CTA, no edit button - read-only memory
class MemoryPage extends ConsumerStatefulWidget {
  final String memoryId;

  const MemoryPage({
    super.key,
    required this.memoryId,
  });

  @override
  ConsumerState<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends ConsumerState<MemoryPage> {
  @override
  void initState() {
    super.initState();
    // Refresh data when page is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  /// Refresh memory data
  void _refreshData() {
    ref.invalidate(memoryDetailProvider(widget.memoryId));
  }

  @override
  Widget build(BuildContext context) {
    final memoryAsync = ref.watch(memoryDetailProvider(widget.memoryId));

    // Get event status from fake config (TODO: get from event provider in P2)
    final eventStatus = FakeMemoryConfig.eventStatus;
    final isHost = FakeMemoryConfig.isHost;
    final userHasUploadedPhotos = FakeMemoryConfig.userHasUploadedPhotos;

    // Build AppBar based on event status
    final appBar = _buildAppBar(
      context,
      ref,
      memoryAsync,
      eventStatus,
      isHost,
      userHasUploadedPhotos,
    );

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: appBar,
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate and wait for memory data to refetch
          _refreshData();
          await ref.read(memoryDetailProvider(widget.memoryId).future);
        },
        color: BrandColors.planning,
        backgroundColor: BrandColors.bg2,
        child: memoryAsync.when(
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
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Gaps.sm),

                  // CTA Banner: Show for living/recap if user hasn't uploaded photos
                  if (_shouldShowCtaBanner(eventStatus, userHasUploadedPhotos))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.screenH,
                      ),
                      child: eventStatus == FakeEventStatus.living
                          ? AddPhotosCtaCard.living(
                              onPressed: () => _navigateToManageMemory(context),
                            )
                          : AddPhotosCtaCard.recap(
                              onPressed: () => _navigateToManageMemory(context),
                            ),
                    ),

                  if (_shouldShowCtaBanner(eventStatus, userHasUploadedPhotos))
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
                    onPhotoTap: (photoId) =>
                        _navigateToViewer(context, photoId),
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
                    onPhotoTap: (photoId) =>
                        _navigateToViewer(context, photoId),
                  ),

                  const SizedBox(height: Gaps.md),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
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
          ),
        ),
      ),
    );
  }

  /// Check if CTA banner should be shown
  /// Show for living/recap events when user hasn't uploaded photos yet
  bool _shouldShowCtaBanner(
    FakeEventStatus eventStatus,
    bool userHasUploadedPhotos,
  ) {
    return (eventStatus == FakeEventStatus.living ||
            eventStatus == FakeEventStatus.recap) &&
        !userHasUploadedPhotos;
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

  /// Build AppBar based on event status
  /// - Recap: AppBarWithSubtitle showing countdown timer with chat button
  /// - Living/Ended: CommonAppBar
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<MemoryEntity?> memoryAsync,
    FakeEventStatus eventStatus,
    bool isHost,
    bool userHasUploadedPhotos,
  ) {
    final leading = IconButton(
      icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
      onPressed: () => Navigator.of(context).pop(),
    );

    // Recap state: show countdown timer with chat button (and edit if applicable)
    if (eventStatus == FakeEventStatus.recap) {
      final subtitle = 'Closes in ${FakeMemoryConfig.formattedRemainingTime}';
      final subtitleColor = FakeMemoryConfig.isLessThanOneHour
          ? BrandColors.cantVote // Orange/red when <1hr
          : BrandColors.text2;

      // Chat button (always present in recap)
      final chatButton = IconButton(
        icon: const Icon(Icons.chat_bubble_outline, color: BrandColors.text1),
        onPressed: () => _navigateToChat(context),
      );

      // Edit button (only if host or has uploaded photos)
      final editButton = (isHost || userHasUploadedPhotos)
          ? IconButton(
              icon: const Icon(Icons.edit, color: BrandColors.text1),
              onPressed: () => _navigateToManageMemory(context),
            )
          : null;

      return AppBarWithSubtitle(
        title: 'Memory',
        subtitle: subtitle,
        subtitleColor: subtitleColor,
        leading: leading,
        trailing: editButton,
        trailing2: chatButton,
      );
    }

    // Living/Ended: standard AppBar with edit button (if applicable)
    final trailing = memoryAsync.maybeWhen(
      data: (memory) => memory != null
          ? _buildTrailingIcon(
              context,
              ref,
              memory,
              eventStatus,
              isHost,
              userHasUploadedPhotos,
            )
          : null,
      orElse: () => null,
    );

    return CommonAppBar(
      title: 'Memory',
      leading: leading,
      trailing: trailing,
    );
  }

  /// Build trailing icon based on event status and permissions
  /// - Living/Recap: Edit button if user is host OR has uploaded photos
  /// - Ended: No button (read-only)
  Widget? _buildTrailingIcon(
    BuildContext context,
    WidgetRef ref,
    MemoryEntity memory,
    FakeEventStatus eventStatus,
    bool isHost,
    bool userHasUploadedPhotos,
  ) {
    // Ended state: no edit button (read-only)
    if (eventStatus == FakeEventStatus.ended) {
      return null;
    }

    // Living/Recap state: show edit if user is host OR has uploaded photos
    if (isHost || userHasUploadedPhotos) {
      return IconButton(
        icon: const Icon(Icons.edit, color: BrandColors.text1),
        onPressed: () => _navigateToManageMemory(context),
      );
    }

    // No icon for users who haven't uploaded
    return null;
  }

  /// Navigate to manage memory page
  Future<void> _navigateToManageMemory(BuildContext context) async {
    final result = await Navigator.of(context).pushNamed(
      AppRouter.manageMemory,
      arguments: {
        'memoryId': widget.memoryId,
      },
    );

    // Refresh memory data if changes were made
    if (result == true && mounted) {
      // Force complete refresh by invalidating and immediately reading the future
      // This ensures we wait for fresh data from Supabase before rebuilding
      ref.invalidate(memoryDetailProvider(widget.memoryId));
      try {
        await ref.read(memoryDetailProvider(widget.memoryId).future);
      } catch (e) {
        // Handle error silently, provider will show error state
      }
    }
  }

  /// Navigate to event chat page
  void _navigateToChat(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRouter.eventChat,
      arguments: {
        'eventId': widget.memoryId, // Using memoryId as eventId
      },
    );
  }

  /// Navigate to memory viewer page
  void _navigateToViewer(BuildContext context, String photoId) {
    Navigator.of(context).pushNamed(
      AppRouter.memoryViewer,
      arguments: {
        'memoryId': widget.memoryId,
        'photoId': photoId,
      },
    );
  }
}
