import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/manage_memory_providers.dart';
import '../widgets/cover_selection_card.dart';
import '../widgets/photo_grid_item.dart';

/// Manage Memory page for editing photos and selecting covers
/// Accessible by:
/// - Event host (always)
/// - Users who have uploaded at least one photo
///
/// Structure:
/// - App bar with back button and "Manage Photos" title
/// - Cover selection card (tap to select from grid, remove with X)
/// - Photos section with user photos first, then others
/// - Each user photo has remove button
class ManageMemoryPage extends ConsumerWidget {
  final String memoryId;

  const ManageMemoryPage({
    super.key,
    required this.memoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manageState = ref.watch(manageMemoryProvider(memoryId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: 'Manage Photos',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: manageState.when(
        data: (state) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Gaps.lg),

                // Cover selection card
                CoverSelectionCard(
                  selectedPhoto: state.selectedCover,
                  onTap: () => _showPhotoSelector(context, ref, state),
                  onRemove: state.selectedCover != null
                      ? () => ref
                          .read(manageMemoryProvider(memoryId).notifier)
                          .removeCover()
                      : null,
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

                // Photos grid (3 columns)
                _buildPhotoGrid(context, ref, state),

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
    WidgetRef ref,
    ManageMemoryState state,
  ) {
    final photos = state.allPhotos;
    if (photos.isEmpty) {
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

    // Calculate grid dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (Insets.screenH * 2);
    final itemWidth = (availableWidth - (Gaps.xs * 2)) / 3;
    final itemHeight = itemWidth * 5 / 4; // 4:5 aspect ratio

    return Wrap(
      spacing: Gaps.xs,
      runSpacing: Gaps.xs,
      children: photos.map((photo) {
        final isUserPhoto = photo.isUploadedByCurrentUser;
        return PhotoGridItem(
          photo: photo,
          width: itemWidth,
          height: itemHeight,
          showRemoveButton: isUserPhoto,
          onRemove: isUserPhoto
              ? () => ref
                  .read(manageMemoryProvider(memoryId).notifier)
                  .removePhoto(photo.id)
              : null,
          onTap: () => ref
              .read(manageMemoryProvider(memoryId).notifier)
              .selectCover(photo),
        );
      }).toList(),
    );
  }

  void _showPhotoSelector(
    BuildContext context,
    WidgetRef ref,
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
                          .read(manageMemoryProvider(memoryId).notifier)
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
