import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/dialogs/confirmation_dialog.dart';
import '../../../../shared/components/cards/add_photos_cta_card.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/manage_memory_providers.dart';
import '../widgets/cover_selection_card.dart';
import '../widgets/photo_grid_item.dart';
import '../widgets/add_photo_card.dart';
import '../../data/fakes/fake_memory_repository.dart';

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

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: 'Manage Photos',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
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
        data: (state) => Stack(
          children: [
            // Main content with scroll
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: Insets.screenH,
                  right: Insets.screenH,
                  bottom: _isSelectionMode ? 90 : 0, // Space for bottom button
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Gaps.lg),

                    // Show CTA banner if user has no photos, otherwise show cover selection
                    if (!FakeMemoryConfig.userHasUploadedPhotos)
                      FakeMemoryConfig.eventStatus == FakeEventStatus.living
                          ? AddPhotosCtaCard.living(
                              onPressed: () => _handleAddPhoto(),
                            )
                          : AddPhotosCtaCard.recap(
                              onPressed: () => _handleAddPhoto(),
                            )
                    else
                      Center(
                        child: CoverSelectionCard(
                          selectedPhoto: state.selectedCover,
                          onTap: () => _showPhotoSelector(context, state),
                          onRemove: state.selectedCover != null
                              ? () => ref
                                  .read(manageMemoryProvider(widget.memoryId)
                                      .notifier)
                                  .removeCover()
                              : null,
                        ),
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

    // Add "Add Photo" card if there's space
    if (hasSpace) {
      gridItems.add(
        AddPhotoCard(
          width: itemWidth,
          height: itemHeight,
          isLiving: FakeMemoryConfig.eventStatus == FakeEventStatus.living,
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

    setState(() {
      _selectedPhotoIds.clear();
      _isSelectionMode = false; // Exit selection mode after deletion
    });

    if (context.mounted) {
      TopBanner.show(context, message: 'Photos deleted');
    }
  }

  void _handleAddPhoto() {
    // TODO: Implement photo picker
    TopBanner.showSuccess(
      context,
      message: FakeMemoryConfig.eventStatus == FakeEventStatus.living
          ? 'Opening camera...'
          : 'Opening photo picker...',
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
