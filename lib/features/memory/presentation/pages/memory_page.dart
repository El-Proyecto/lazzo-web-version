import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/invite_bottom_sheet.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/inputs/photo_selector.dart';
import '../../../../shared/components/sections/cover_mosaic.dart';
import '../../../../shared/components/sections/hybrid_photo_grid.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../event/domain/entities/rsvp.dart';
import '../../../event/presentation/providers/event_providers.dart';
import '../../../event_invites/presentation/providers/event_invite_providers.dart';
import '../providers/memory_providers.dart';
import '../../domain/entities/memory_entity.dart';

/// Memory page displaying event photos with state-based UI
///
/// Layout (top to bottom):
/// 1. AppBar: emoji + title, edit icon + share icon
/// 2. Info: location + date, avatar row, stats text
/// 3. CoverMosaic + HybridPhotoGrid (continuous)
/// 4. Bottom banner: "Add your photos" (recap/living only)
///
/// Three states based on event status:
/// - Living: edit + banner, purple accents
/// - Recap: edit + banner with timer, orange accents
/// - Ended: read-only, no banner
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    ref.invalidate(memoryDetailProvider(widget.memoryId));
  }

  @override
  Widget build(BuildContext context) {
    final memoryAsync = ref.watch(memoryDetailProvider(widget.memoryId));
    final rsvpsAsync = ref.watch(eventRsvpsProvider(widget.memoryId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return memoryAsync.when(
      loading: () => Scaffold(
        backgroundColor: BrandColors.bg1,
        appBar: CommonAppBar(
          title: '',
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
          title: '',
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
              title: '',
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
        final userHasUploadedPhotos = currentUserId != null &&
            memory.photos.any((photo) => photo.uploaderId == currentUserId);

        final coverPhotos = memory.coverPhotos;
        final gridPhotos = memory.gridPhotos;

        // Get participants from RSVPs
        final participants = rsvpsAsync.when<List<Rsvp>>(
          data: (rsvps) =>
              rsvps.where((r) => r.status == RsvpStatus.going).toList(),
          loading: () => <Rsvp>[],
          error: (_, __) => <Rsvp>[],
        );
        final participantCount = participants.length;

        // Compute stats
        final totalPhotos = memory.photos.length;

        // Calculate "last added X ago" for recap
        String? lastAddedText;
        if (eventStatus == EventStatus.recap && memory.photos.isNotEmpty) {
          final sorted = List<MemoryPhoto>.from(memory.photos)
            ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
          lastAddedText = _formatTimeAgo(sorted.first.capturedAt);
        }

        // Should show edit icon: only for ended events (recap has its own page)
        final showEditIcon = eventStatus == EventStatus.ended &&
            (isHost || userHasUploadedPhotos);

        // Should show bottom banner
        final showBottomBanner = _shouldShowBottomBanner(
          eventStatus,
          userHasUploadedPhotos,
        );

        return Scaffold(
          backgroundColor: BrandColors.bg1,
          appBar: _buildAppBar(context, memory, showEditIcon),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  _refreshData();
                  await ref.read(memoryDetailProvider(widget.memoryId).future);
                },
                color: BrandColors.planning,
                backgroundColor: BrandColors.bg2,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          kToolbarHeight -
                          MediaQuery.of(context).padding.top -
                          (showBottomBanner ? 0 : 0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Info Section ──
                        // Location • Date
                        Text(
                          _buildSubtitle(memory.location, memory.eventDate),
                          style: AppText.bodyMedium.copyWith(
                            color: BrandColors.text2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: Gaps.sm),

                        // Avatar row (tappable -> manage guests)
                        if (participants.isNotEmpty)
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  AppRouter.manageGuests,
                                  arguments: {'eventId': widget.memoryId},
                                );
                              },
                              child: _buildAvatarRow(participants),
                            ),
                          ),

                        const SizedBox(height: Gaps.sm),

                        Text(
                          _buildStatsText(
                            totalPhotos,
                            participantCount,
                            lastAddedText,
                          ),
                          style: AppText.bodyMedium.copyWith(
                            color: BrandColors.text2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: Gaps.md),

                        // ── Empty State or Content ──
                        if (memory.photos.isEmpty)
                          GestureDetector(
                            onTap: () =>
                                _handleAddPhotosFromCta(context, eventStatus),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: Insets.screenH,
                              ),
                              padding: const EdgeInsets.all(Gaps.lg),
                              decoration: BoxDecoration(
                                color: BrandColors.bg2,
                                borderRadius: BorderRadius.circular(Radii.md),
                                border: Border.all(
                                  color: BrandColors.bg3,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.photo_library_outlined,
                                    size: 48,
                                    color: BrandColors.text2,
                                  ),
                                  const SizedBox(height: Gaps.md),
                                  Text(
                                    'No photos yet',
                                    style: AppText.titleMediumEmph.copyWith(
                                      color: BrandColors.text1,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: Gaps.xs),
                                  Text(
                                    eventStatus == EventStatus.recap
                                        ? 'Add your photos to create the memory'
                                        : 'Photos will appear here once added',
                                    style: AppText.bodyMedium.copyWith(
                                      color: BrandColors.text2,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // ── Cover Mosaic ──
                        if (memory.photos.isNotEmpty)
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

                        // ── Photo Grid (continuous after cover) ──
                        if (gridPhotos.isNotEmpty)
                          const SizedBox(height: Gaps.xs),

                        if (gridPhotos.isNotEmpty)
                          HybridPhotoGrid(
                            clusters: _buildClusters(gridPhotos),
                            onPhotoTap: (photoId) =>
                                _navigateToViewer(context, photoId),
                          ),

                        // Extra space for bottom banner
                        SizedBox(height: showBottomBanner ? 120 : Gaps.xl),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Fixed Bottom Banner ──
              if (showBottomBanner)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomBanner(context, eventStatus, memory),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── AppBar ──────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    MemoryEntity memory,
    bool showEditIcon,
  ) {
    final titleWithEmoji = '${memory.emoji} ${memory.title}';
    debugPrint('[MemoryPage] AppBar emoji: "${memory.emoji}"');
    debugPrint('[MemoryPage] AppBar title: "${memory.title}"');
    debugPrint('[MemoryPage] AppBar titleWithEmoji: "$titleWithEmoji"');

    return CommonAppBar(
      title: titleWithEmoji,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.mainLayout,
              (route) => false,
            );
          }
        },
      ),
      trailing: showEditIcon
          ? IconButton(
              icon: const Icon(Icons.photo_library_outlined,
                  color: BrandColors.text1),
              onPressed: () => _navigateToManageMemory(context),
            )
          : null,
      trailing2: IconButton(
        icon: const Icon(Icons.ios_share, color: BrandColors.text1),
        onPressed: () => _navigateToShareMemory(
          context,
          memory.status,
          memory.eventId,
          memory.title,
          memory.emoji,
        ),
      ),
    );
  }

  // ─── Avatar Row ──────────────────────────────────────────

  Widget _buildAvatarRow(List<Rsvp> participants) {
    const maxAvatars = 6;
    final visible = participants.take(maxAvatars).toList();
    final overflow = participants.length - maxAvatars;

    // Calculate actual width: each avatar 36px minus 8px overlap per avatar after first
    final totalAvatars = overflow > 0 ? maxAvatars + 1 : visible.length;
    final width = 36.0 + (28.0 * (totalAvatars - 1));

    return SizedBox(
      width: width,
      height: 36,
      child: Stack(
        children: [
          ...visible.asMap().entries.map((entry) {
            final index = entry.key;
            final participant = entry.value;
            return Positioned(
              left: index * 28.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: BrandColors.bg1, width: 2),
                ),
                child: ClipOval(
                  child: participant.userAvatar != null
                      ? Image.network(
                          participant.userAvatar!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildDefaultAvatarSmall(participant.userName),
                        )
                      : _buildDefaultAvatarSmall(participant.userName),
                ),
              ),
            );
          }),
          if (overflow > 0)
            Positioned(
              left: visible.length * 28.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BrandColors.bg3,
                  border: Border.all(color: BrandColors.bg1, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$overflow',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatarSmall(String name) {
    return Container(
      width: 32,
      height: 32,
      color: BrandColors.bg3,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppText.labelLarge.copyWith(
            color: BrandColors.text2,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ─── Bottom Banner ───────────────────────────────────────

  bool _shouldShowBottomBanner(
    EventStatus eventStatus,
    bool userHasUploadedPhotos,
  ) {
    // Always show for recap, show for living only if user hasn't uploaded
    if (eventStatus == EventStatus.recap) {
      return true;
    }
    if (eventStatus == EventStatus.living) {
      return !userHasUploadedPhotos;
    }
    return false;
  }

  Widget _buildBottomBanner(
    BuildContext context,
    EventStatus eventStatus,
    MemoryEntity memory,
  ) {
    final isRecap = eventStatus == EventStatus.recap;
    final buttonColor = isRecap ? BrandColors.recap : BrandColors.living;

    String subtitle;
    if (isRecap && memory.recapTimeRemaining != null) {
      subtitle = 'Recap closes in ${memory.formattedRecapTimeRemaining}';
    } else {
      subtitle = 'You can then select a photo cover';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.screenH,
        vertical: Gaps.md,
      ),
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        border: Border(
          top: BorderSide(color: BrandColors.bg3, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add your photos',
                    style: AppText.titleMediumEmph.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                  const SizedBox(height: Gaps.xxs),
                  Text(
                    subtitle,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gaps.md),
            GestureDetector(
              onTap: () => _handleAddPhotosFromCta(context, eventStatus),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(Radii.smAlt),
                ),
                child: Icon(
                  isRecap ? Icons.add_photo_alternate : Icons.camera_alt,
                  color: BrandColors.text1,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────

  String _buildSubtitle(String? location, DateTime eventDate) {
    final dateStr = DateFormat('d MMM yyyy').format(eventDate);
    if (location != null && location.isNotEmpty) {
      final shortLocation =
          location.contains(',') ? location.split(',').first.trim() : location;
      return '$shortLocation • $dateStr';
    }
    return dateStr;
  }

  String _buildStatsText(
    int totalPhotos,
    int participantCount,
    String? lastAddedText,
  ) {
    final buffer = StringBuffer();
    buffer.write('$totalPhotos photos \u2022 $participantCount participants');
    if (lastAddedText != null) {
      buffer.write(' \u2022 last added $lastAddedText');
    }
    return buffer.toString();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

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

  // ─── Navigation ──────────────────────────────────────────

  Future<void> _navigateToManageMemory(BuildContext context) async {
    ref.invalidate(memoryDetailProvider(widget.memoryId));

    await Navigator.of(context).pushNamed(
      AppRouter.manageMemory,
      arguments: {'memoryId': widget.memoryId},
    );

    if (mounted) {
      ref.invalidate(memoryDetailProvider(widget.memoryId));
      try {
        await ref.read(memoryDetailProvider(widget.memoryId).future);
      } catch (e) {
        // Provider will show error state
      }
    }
  }

  Future<void> _navigateToShareMemory(
    BuildContext context,
    EventStatus status,
    String eventId,
    String eventName,
    String eventEmoji,
  ) async {
    // Recap/Living: Show invite bottom sheet with invite link
    if (status == EventStatus.recap || status == EventStatus.living) {
      try {
        final useCase = ref.read(createEventInviteLinkProvider);
        final entity = await useCase(
          eventId: eventId,
          shareChannel: 'memory_share',
        );
        final inviteUrl = '${AppConfig.invitesBaseUrl}/i/${entity.token}';
        if (context.mounted) {
          InviteBottomSheet.show(
            context: context,
            inviteUrl: inviteUrl,
            entityName: eventName,
            entityType: 'event',
            eventEmoji: eventEmoji,
          );
        }
      } catch (e) {
        if (context.mounted) {
          TopBanner.showError(context, message: 'Failed to create invite link');
        }
      }
      return;
    }

    // Ended: Navigate to ShareMemoryPage for full share experience
    Navigator.of(context).pushNamed(
      AppRouter.shareMemory,
      arguments: {'memoryId': widget.memoryId},
    );
  }

  void _navigateToViewer(BuildContext context, String photoId) {
    Navigator.of(context).pushNamed(
      AppRouter.memoryViewer,
      arguments: {
        'memoryId': widget.memoryId,
        'photoId': photoId,
      },
    );
  }

  Future<void> _handleAddPhotosFromCta(
      BuildContext context, EventStatus eventStatus) async {
    if (eventStatus == EventStatus.living) {
      if (!mounted || !context.mounted) return;
      PhotoSelectionBottomSheet.show(
        context: context,
        title: 'Add Photo',
        showRemoveOption: false,
        onAction: (action) async {
          if (action == PhotoSourceAction.camera) {
            final picker = ImagePicker();
            final photo = await picker.pickImage(
              source: ImageSource.camera,
              maxWidth: 1920,
              maxHeight: 1920,
              imageQuality: 85,
            );
            if (photo != null && mounted && context.mounted) {
              final result = await Navigator.of(context).pushNamed(
                AppRouter.manageMemory,
                arguments: {
                  'memoryId': widget.memoryId,
                  'selectedPhotos': [photo.path],
                },
              );
              if (result == true && mounted) {
                ref.invalidate(memoryDetailProvider(widget.memoryId));
              }
            }
          } else if (action == PhotoSourceAction.gallery) {
            await _pickFromGalleryAndNavigate(context);
          }
        },
      );
    } else {
      await _pickFromGalleryAndNavigate(context);
    }
  }

  Future<void> _pickFromGalleryAndNavigate(BuildContext context) async {
    final picker = ImagePicker();
    final selectedImages = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (selectedImages.isNotEmpty && mounted) {
      final limitedImages = selectedImages.take(5).toList();

      if (limitedImages.length < selectedImages.length) {
        if (!mounted || !context.mounted) return;
        TopBanner.showInfo(context, message: 'Maximum 5 photos selected');
      }

      if (!mounted || !context.mounted) return;
      final result = await Navigator.of(context).pushNamed(
        AppRouter.manageMemory,
        arguments: {
          'memoryId': widget.memoryId,
          'selectedPhotos': limitedImages.map((img) => img.path).toList(),
        },
      );

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
}
