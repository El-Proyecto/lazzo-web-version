import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/dialogs/confirmation_dialog.dart';
import '../../../../shared/components/cards/add_photos_cta_card.dart';
import '../../../../shared/components/inputs/photo_selector.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../event/presentation/providers/event_providers.dart';
import '../../../event/presentation/providers/event_photo_providers.dart';
import '../providers/manage_memory_providers.dart';
import '../providers/memory_providers.dart';
import '../widgets/cover_selection_card.dart';
import '../widgets/photo_grid_item.dart';
import '../widgets/add_photo_card.dart';

/// Manage Memory page for editing photos and selecting covers
/// Accessible by:
/// - Event host (always)
/// - Users who have uploaded at least one photo
///
/// Structure:
/// - App bar with back button, "Manage Photos" title, and selection delete icon
/// - Cover selection card (tap to select from grid, no cover by default)
/// - Photos section with user photos first, then others
/// - Selection mode: only user's photos (or all if host) can be selected
/// - Add photo card at the end if space available
class ManageMemoryPage extends ConsumerStatefulWidget {
  final String memoryId;

  const ManageMemoryPage({
    super.key,
    required this.memoryId,
  });

  @override
  ConsumerState<ManageMemoryPage> createState() => _ManageMemoryPageState();
}

class _ManageMemoryPageState extends ConsumerState<ManageMemoryPage> {
  bool _isSelectionMode = false;
  final Set<String> _selectedPhotoIds = {};
  bool _hasSetSelectedPhotos =
      false; // Track if selectedPhotos were already set

  @override
  void initState() {
    super.initState();
    // Set selected photos only once on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final selectedPhotos = args?['selectedPhotos'] as List<String>?;

      if (selectedPhotos != null &&
          selectedPhotos.isNotEmpty &&
          !_hasSetSelectedPhotos) {
        _hasSetSelectedPhotos = true;
        ref.read(selectedPhotoPathsProvider.notifier).state = selectedPhotos;
      }
    });
  }

  bool _hasChanges = false; // Track if any changes were made

  Future<void> refreshMemoryData() async {
    // Invalidate providers to trigger a fresh data fetch
    ref.invalidate(manageMemoryProvider(widget.memoryId));
    ref.invalidate(memoryDetailProvider(widget.memoryId));
    ref.invalidate(eventDetailProvider(widget.memoryId));
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedPhotoIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final manageState = ref.watch(manageMemoryProvider(widget.memoryId));

    // Get event details to determine status and host (memoryId is eventId)
    final eventAsync = ref.watch(eventDetailProvider(widget.memoryId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: 'Manage Photos',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(_hasChanges),
        ),
        trailing: IconButton(
          icon: Icon(
            _isSelectionMode ? Icons.close : Icons.delete_outline,
            color: _isSelectionMode ? BrandColors.text1 : BrandColors.text1,
          ),
          onPressed: _toggleSelectionMode,
        ),
      ),
      body: manageState.when(
        data: (state) => RefreshIndicator(
          onRefresh: refreshMemoryData,
          color: BrandColors.living,
          child: Stack(
            children: [
              // Main content with scroll
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: Insets.screenH,
                    right: Insets.screenH,
                    bottom: _isSelectionMode
                        ? ((MediaQuery.of(context).size.height * 0.36)
                            .clamp(200.0, 400.0))
                        : Gaps.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Gaps.lg),

                      // Show CTA banner if no photos exist yet, otherwise show cover selection
                      // CTA encourages first upload, cover selection manages existing photos
                      if (state.allPhotos.isEmpty)
                        // Determine banner type based on event status
                        ...eventAsync.when(
                          data: (event) {
                            final isLiving =
                                event.status.toString().split('.').last ==
                                    'living';
                            return [
                              isLiving
                                  ? AddPhotosCtaCard.living(
                                      onPressed: () => _handleAddPhoto(),
                                    )
                                  : AddPhotosCtaCard.recap(
                                      onPressed: () => _handleAddPhoto(),
                                    ),
                            ];
                          },
                          loading: () => [
                            AddPhotosCtaCard.living(
                              onPressed: () => _handleAddPhoto(),
                            ),
                          ],
                          error: (_, __) => [
                            AddPhotosCtaCard.living(
                              onPressed: () => _handleAddPhoto(),
                            ),
                          ],
                        )
                      else
                        Builder(
                          builder: (context) {
                            if (state.selectedCover != null) {}

                            return Center(
                              child: CoverSelectionCard(
                                selectedPhoto: state.selectedCover,
                                onTap: () => _showPhotoSelector(context, state),
                                onRemove: state.selectedCover != null
                                    ? () {
                                        setState(() => _hasChanges = true);
                                        ref
                                            .read(manageMemoryProvider(
                                                    widget.memoryId)
                                                .notifier)
                                            .removeCover();
                                      }
                                    : null,
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: Gaps.xl),

                      // Photos section header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Photos',
                            style: AppText.titleMediumEmph.copyWith(
                              color: BrandColors.text1,
                            ),
                          ),
                          Text(
                            '${state.allPhotos.length}/${state.maxPhotos}',
                            style: AppText.bodyMedium.copyWith(
                              color: BrandColors.text2,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: Gaps.md),

                      // Photos grid (3 columns) + Add card
                      _buildPhotoGrid(context, state),

                      const SizedBox(height: Gaps.xl),
                    ],
                  ),
                ),
              ),

              // Bottom delete button (only show in selection mode)
              if (_isSelectionMode)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(Insets.screenH),
                    decoration: const BoxDecoration(
                      color: BrandColors.bg2,
                      border: Border(
                        top: BorderSide(color: BrandColors.bg3, width: 1),
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _handleDeleteSelected(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColors.cantVote,
                        padding:
                            const EdgeInsets.symmetric(vertical: Pads.ctlVSm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.smAlt),
                        ),
                      ),
                      child: Text(
                        'Delete ${_selectedPhotoIds.length} photo(s)',
                        style: AppText.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error loading photos: $error',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(
    BuildContext context,
    ManageMemoryState state,
  ) {
    final photos = state.allPhotos;
    final hasSpace = photos.length < state.maxPhotos;

    // Calculate grid dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (Insets.screenH * 2);
    final itemWidth = (availableWidth - (Gaps.xs * 2)) / 3;
    final itemHeight = itemWidth * 5 / 4; // 4:5 aspect ratio

    final gridItems = <Widget>[
      ...photos.map((photo) {
        final isUserPhoto = photo.isUploadedByCurrentUser;
        final canSelect = state.isHost || isUserPhoto;
        final isSelected = _selectedPhotoIds.contains(photo.id);

        return PhotoGridItem(
          photo: photo,
          width: itemWidth,
          height: itemHeight,
          canSelect: canSelect,
          isSelected: isSelected,
          isSelectionMode: _isSelectionMode,
          onTap: () => _handlePhotoTap(context, photo, canSelect, state),
          onSelectionChanged: (selected) =>
              _handleSelectionChanged(photo.id, selected),
        );
      }),
    ];

    // Add "Add Photo" card if there's space AND not in selection mode
    if (hasSpace && !_isSelectionMode) {
      // Determine if event is in living mode from event details
      final eventAsync = ref.watch(eventDetailProvider(widget.memoryId));
      final isLiving = eventAsync.maybeWhen(
        data: (event) => event.status.toString().split('.').last == 'living',
        orElse: () => false,
      );

      gridItems.add(
        AddPhotoCard(
          width: itemWidth,
          height: itemHeight,
          isLiving: isLiving,
          onTap: () => _handleAddPhoto(),
        ),
      );
    }

    if (gridItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Gaps.xl),
          child: Text(
            'No photos yet',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: Gaps.xs,
      runSpacing: Gaps.xs,
      children: gridItems,
    );
  }

  void _handlePhotoTap(
    BuildContext context,
    ManagePhotoItem photo,
    bool canSelect,
    ManageMemoryState state,
  ) {
    // If in selection mode, toggle selection or show error
    if (_isSelectionMode) {
      if (!canSelect) {
        TopBanner.showError(
          context,
          message: "You can't select other people's photos",
        );
        return;
      }
      _handleSelectionChanged(photo.id, !_selectedPhotoIds.contains(photo.id));
      return;
    }

    // Normal mode: open photo preview
    _navigateToPhotoPreview(context, photo.id);
  }

  /// Navigate to photo preview page
  void _navigateToPhotoPreview(BuildContext context, String photoId) {
    Navigator.of(context).pushNamed(
      AppRouter.photoPreview,
      arguments: {
        'memoryId': widget.memoryId,
        'photoId': photoId,
      },
    );
  }

  void _handleSelectionChanged(String photoId, bool selected) {
    setState(() {
      if (selected) {
        _selectedPhotoIds.add(photoId);
      } else {
        _selectedPhotoIds.remove(photoId);
      }
    });
  }

  /// Handle actual deletion when bottom button is pressed
  Future<void> _handleDeleteSelected(BuildContext context) async {
    if (_selectedPhotoIds.isEmpty) return;

    // Show confirmation dialog using common component
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Photos',
        message: 'Delete ${_selectedPhotoIds.length} photo(s)?',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: () {},
      ),
    );

    if (confirmed != true && confirmed != null) return;

    // Delete selected photos
    for (final photoId in _selectedPhotoIds) {
      await ref
          .read(manageMemoryProvider(widget.memoryId).notifier)
          .removePhoto(photoId);
    }

    // Invalidate memory provider to refresh Memory page when user goes back
    ref.invalidate(memoryDetailProvider(widget.memoryId));

    setState(() {
      _hasChanges = true; // Mark that changes were made
      _selectedPhotoIds.clear();
      _isSelectionMode = false; // Exit selection mode after deletion
    });

    if (context.mounted) {
      TopBanner.showSuccess(context, message: 'Photos deleted');
    }
  }

  void _handleAddPhoto() async {
    // Get event details for status check
    final eventAsync = ref.read(eventDetailProvider(widget.memoryId));

    eventAsync.when(
      data: (event) async {
        final status = event.status.toString().split('.').last;
        final isLiving = status == 'living';

        if (isLiving) {
          // Living: show photo source selector (camera / gallery)
          if (!mounted) return;
          PhotoSelectionBottomSheet.show(
            context: context,
            showRemoveOption: false,
            onAction: (action) async {
              final photoNotifier = ref.read(
                eventPhotoUploadNotifierProvider(widget.memoryId).notifier,
              );

              if (action == PhotoSourceAction.camera) {
                await photoNotifier.takePhoto(eventId: widget.memoryId);
              } else if (action == PhotoSourceAction.gallery) {
                await photoNotifier.pickPhotoFromGallery(
                    eventId: widget.memoryId);
              }

              _showPhotoUploadResult();
            },
          );
        } else {
          // Recap: only gallery
          final photoNotifier = ref.read(
            eventPhotoUploadNotifierProvider(widget.memoryId).notifier,
          );
          await photoNotifier.pickPhotoFromGallery(eventId: widget.memoryId);
          _showPhotoUploadResult();
        }
      },
      loading: () {},
      error: (_, __) {
        if (mounted) {
          TopBanner.showError(context, message: 'Event not loaded');
        }
      },
    );
  }

  void _showPhotoUploadResult() {
    final uploadState = ref.read(
      eventPhotoUploadNotifierProvider(widget.memoryId),
    );

    uploadState.when(
      data: (photoUrl) {
        if (photoUrl != null) {
          if (mounted) {
            TopBanner.showSuccess(
              context,
              message: 'Photo uploaded successfully!',
            );
          }

          ref.invalidate(manageMemoryProvider(widget.memoryId));
          ref.invalidate(memoryDetailProvider(widget.memoryId));
          ref.invalidate(eventDetailProvider(widget.memoryId));

          setState(() => _hasChanges = true);
        }
      },
      loading: () {},
      error: (error, _) {
        if (mounted) {
          TopBanner.showError(
            context,
            message: '❌ Failed to upload photo: $error',
          );
        }
      },
    );
  }

  void _showPhotoSelector(
    BuildContext context,
    ManageMemoryState state,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BrandColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(Insets.screenH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select a cover',
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text1,
              ),
            ),
            const SizedBox(height: Gaps.md),
            SizedBox(
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: Gaps.xs,
                  mainAxisSpacing: Gaps.xs,
                  childAspectRatio: 4 / 5,
                ),
                itemCount: state.allPhotos.length,
                itemBuilder: (context, index) {
                  final photo = state.allPhotos[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() =>
                          _hasChanges = true); // Mark that changes were made
                      ref
                          .read(manageMemoryProvider(widget.memoryId).notifier)
                          .selectCover(photo);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Radii.sm),
                        image: DecorationImage(
                          image: NetworkImage(photo.thumbnailUrl ?? photo.url),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
