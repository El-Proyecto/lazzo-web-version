import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/manage_memory_providers.dart';
import '../widgets/cover_selection_card.dart';
import '../widgets/photo_grid_item.dart';
import '../widgets/add_photo_card.dart';
import 'memory_page.dart';

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
  final MemoryEventState state;

  const ManageMemoryPage({
    super.key,
    required this.memoryId,
    this.state = MemoryEventState.recap,
  });

  @override
  ConsumerState<ManageMemoryPage> createState() => _ManageMemoryPageState();
}

class _ManageMemoryPageState extends ConsumerState<ManageMemoryPage> {
  final Set<String> _selectedPhotoIds = {};
  bool get _isSelectionMode => _selectedPhotoIds.isNotEmpty;
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
        trailing: _isSelectionMode
            ? IconButton(
                icon:
                    const Icon(Icons.delete_outline, color: BrandColors.text1),
                onPressed: () => _handleDeleteSelected(context),
              )
            : null,
      ),
      body: manageState.when(
        data: (state) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Gaps.lg),

                // Cover selection card (centered)
                Center(
                  child: CoverSelectionCard(
                    selectedPhoto: state.selectedCover,
                    onTap: () => _showPhotoSelector(context, state),
                    onRemove: state.selectedCover != null
                        ? () => ref
                            .read(
                                manageMemoryProvider(widget.memoryId).notifier)
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
          isLiving: widget.state == MemoryEventState.living,
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
    // If in selection mode, toggle selection
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

    // Normal mode: open memory viewer
    _navigateToViewer(context, photo.id);
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

  void _handleSelectionChanged(String photoId, bool selected) {
    setState(() {
      if (selected) {
        _selectedPhotoIds.add(photoId);
      } else {
        _selectedPhotoIds.remove(photoId);
      }
    });
  }

  Future<void> _handleDeleteSelected(BuildContext context) async {
    if (_selectedPhotoIds.isEmpty) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrandColors.bg2,
        title: Text(
          'Delete Photos',
          style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
        ),
        content: Text(
          'Delete ${_selectedPhotoIds.length} photo(s)?',
          style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppText.labelLarge.copyWith(color: BrandColors.text2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: AppText.labelLarge.copyWith(color: BrandColors.cantVote),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete selected photos
    for (final photoId in _selectedPhotoIds) {
      await ref
          .read(manageMemoryProvider(widget.memoryId).notifier)
          .removePhoto(photoId);
    }

    setState(() {
      _selectedPhotoIds.clear();
    });

    if (context.mounted) {
      TopBanner.showSuccess(context, message: 'Photos deleted');
    }
  }

  void _handleAddPhoto() {
    // TODO: Implement photo picker
    TopBanner.showSuccess(
      context,
      message: widget.state == MemoryEventState.living
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
