import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/nav/app_bar_with_subtitle.dart';
import '../../../../shared/components/cards/add_photos_cta_card.dart';
import '../../../../shared/components/cards/close_recap_card.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/sections/cover_mosaic.dart';
import '../../../../shared/components/sections/hybrid_photo_grid.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../home/presentation/providers/home_event_providers.dart';
import '../providers/memory_providers.dart';
import '../../domain/entities/memory_entity.dart';

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
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return memoryAsync.when(
      loading: () => Scaffold(
        backgroundColor: BrandColors.bg1,
        appBar: CommonAppBar(
          title: 'Memory',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: BrandColors.bg1,
        appBar: CommonAppBar(
          title: 'Memory',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(child: Text('Error: $error')),
      ),
      data: (memory) {
        if (memory == null) {
          return Scaffold(
            backgroundColor: BrandColors.bg1,
            appBar: CommonAppBar(
              title: 'Memory',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(
              child: Text(
                'Memory not found',
                style: TextStyle(color: BrandColors.text2),
              ),
            ),
          );
        }

        final eventStatus = memory.status;
        final isHost =
            currentUserId != null && memory.createdBy == currentUserId;

        // Check if user has uploaded photos
        final userHasUploadedPhotos = currentUserId != null &&
            memory.photos.any((photo) => photo.uploaderId == currentUserId);

        final coverPhotos = memory.coverPhotos;
        final gridPhotos = memory.gridPhotos;

        // Build AppBar based on event status
        final appBar = _buildAppBar(
          context,
          ref,
          eventStatus,
          isHost,
          userHasUploadedPhotos,
          memory,
        );

        return Scaffold(
          backgroundColor: BrandColors.bg1,
          appBar: appBar,
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  // Invalidate and wait for memory data to refetch
                  _refreshData();
                  await ref.read(memoryDetailProvider(widget.memoryId).future);
                },
                color: BrandColors.planning,
                backgroundColor: BrandColors.bg2,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Gaps.sm),

                      // Close Recap Card: Show at top for hosts in recap state with photos
                      if (eventStatus == EventStatus.recap &&
                          isHost &&
                          memory.photos.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Insets.screenH,
                          ),
                          child: CloseRecapCard(
                            timeRemaining: memory.formattedRecapTimeRemaining,
                            onCloseConfirmed: () =>
                                _handleEndRecapEarly(context, ref),
                            isLiving: false,
                          ),
                        ),

                      if (eventStatus == EventStatus.recap &&
                          isHost &&
                          memory.photos.isNotEmpty)
                        const SizedBox(height: Gaps.md),

                      // CTA Banner: Show for living/recap if user hasn't uploaded photos
                      if (_shouldShowCtaBanner(
                          eventStatus, userHasUploadedPhotos))
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Insets.screenH,
                          ),
                          child: eventStatus == EventStatus.living
                              ? AddPhotosCtaCard.living(
                                  onPressed: () =>
                                      _handleAddPhotosFromCta(context),
                                )
                              : AddPhotosCtaCard.recap(
                                  onPressed: () =>
                                      _handleAddPhotosFromCta(context),
                                ),
                        ),

                      if (_shouldShowCtaBanner(
                          eventStatus, userHasUploadedPhotos))
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: Insets.screenH),
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

                      const SizedBox(height: Gaps.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Check if CTA banner should be shown
  /// Show for living/recap events when:
  /// - User hasn't uploaded photos yet (encourage first upload)
  /// Logic: Host always has edit button, non-host sees CTA if no photos
  bool _shouldShowCtaBanner(
    EventStatus eventStatus,
    bool userHasUploadedPhotos,
  ) {
    // Only show during living or recap phases
    if (eventStatus != EventStatus.living && eventStatus != EventStatus.recap) {
      return false;
    }

    // Show CTA if user hasn't uploaded photos yet
    // (Hosts will have edit button instead, non-hosts see CTA to encourage upload)
    return !userHasUploadedPhotos;
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
    EventStatus eventStatus,
    bool isHost,
    bool userHasUploadedPhotos,
    MemoryEntity memory,
  ) {
    final leading = IconButton(
      icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
      onPressed: () {
        // Safe navigation: if no previous route, go to MainLayout (Home)
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.mainLayout,
            (route) => false,
          );
        }
      },
    );

    // Recap state: show countdown timer with chat button (and edit if applicable)
    if (eventStatus == EventStatus.recap) {
      final subtitle = memory.recapTimeRemaining != null
          ? 'Closes in ${memory.formattedRecapTimeRemaining}'
          : 'Closes soon';
      final subtitleColor = memory.isRecapClosingSoon
          ? BrandColors.cantVote // Red when <30min
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
    final trailing = _buildTrailingIcon(
      context,
      ref,
      memory,
      eventStatus,
      isHost,
      userHasUploadedPhotos,
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
    EventStatus eventStatus,
    bool isHost,
    bool userHasUploadedPhotos,
  ) {
    // Ended state: no edit button (read-only)
    if (eventStatus == EventStatus.ended) {
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
    // Invalidate provider before navigation to ensure fresh state
    ref.invalidate(memoryDetailProvider(widget.memoryId));

    await Navigator.of(context).pushNamed(
      AppRouter.manageMemory,
      arguments: {
        'memoryId': widget.memoryId,
      },
    );

    // Always refresh when returning from manage memory
    // This ensures cover selections, photo deletions, etc. are reflected
    if (mounted) {
      ref.invalidate(memoryDetailProvider(widget.memoryId));
      try {
        await ref.read(memoryDetailProvider(widget.memoryId).future);
      } catch (e) {
        // Handle error silently, provider will show error state
      }
    }
  }

  /// Handle add photos from CTA banner
  /// Opens gallery first, then navigates to ManageMemory with selected photos
  Future<void> _handleAddPhotosFromCta(BuildContext context) async {
    final picker = ImagePicker();
    final selectedImages = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (selectedImages.isNotEmpty && mounted) {
      // Limit to 5 photos
      final limitedImages = selectedImages.take(5).toList();

      if (limitedImages.length < selectedImages.length) {
        if (!mounted) return;
        if (!context.mounted) return;
        TopBanner.showInfo(
          context,
          message: 'Maximum 5 photos selected',
        );
      }

      // Navigate to ManageMemory with selected photos
      if (!mounted) return;
      if (!context.mounted) return;
      final result = await Navigator.of(context).pushNamed(
        AppRouter.manageMemory,
        arguments: {
          'memoryId': widget.memoryId,
          'selectedPhotos': limitedImages.map((img) => img.path).toList(),
        },
      );

      // Refresh if changes were made
      if (result == true && mounted) {
        ref.invalidate(memoryDetailProvider(widget.memoryId));
        try {
          await ref.read(memoryDetailProvider(widget.memoryId).future);
        } catch (e) {
          // Handle error silently
        }
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

  /// Handle ending recap early (host action)
  /// Note: Confirmation dialog is already shown by CloseRecapCard
  Future<void> _handleEndRecapEarly(BuildContext context, WidgetRef ref) async {
    try {
      // Update event status to 'ended' in Supabase
      // Trigger handle_event_ended() will automatically call notify_memory_ready()
      await Supabase.instance.client
          .from('events')
          .update({'status': 'ended'}).eq('id', widget.memoryId);

      // Refresh memory data and home data
      ref.invalidate(memoryDetailProvider(widget.memoryId));
      ref.invalidate(nextEventControllerProvider);
      ref.invalidate(confirmedEventsControllerProvider);

      if (context.mounted) {
        // Navigate to MemoryReadyPage
        Navigator.of(context).pushReplacementNamed(
          AppRouter.memoryReady,
          arguments: {
            'memoryId': widget.memoryId,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        TopBanner.showError(
          context,
          message: 'Failed to end recap',
        );
      }
    }
  }
}
