import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/dialogs/confirmation_dialog.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/manage_memory_providers.dart';

/// Photo Preview Page - For managing individual photos in Manage Photos flow
/// Differences from Memory Viewer:
/// - Header: "Photos Preview" title (always visible)
/// - Shows uploader name
/// - Delete button for user's own photos or if host
/// - "Promote to Cover" button at bottom (always visible)
/// - Photos respect layout sizing (not full screen)
/// - Horizontal scroll (no vertical scroll)
/// - No auto-hide UI
class PhotoPreviewPage extends ConsumerStatefulWidget {
  final String memoryId;
  final String? initialPhotoId;

  const PhotoPreviewPage({
    super.key,
    required this.memoryId,
    this.initialPhotoId,
  });

  @override
  ConsumerState<PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends ConsumerState<PhotoPreviewPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manageState = ref.watch(manageMemoryProvider(widget.memoryId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: 'Photos Preview',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: manageState.when(
        data: (state) {
          if (state.allPhotos.isEmpty) {
            return const Center(
              child: Text(
                'No photos available',
                style: TextStyle(color: BrandColors.text2),
              ),
            );
          }

          // Find initial index
          final initialIndex = widget.initialPhotoId != null
              ? state.allPhotos.indexWhere((p) => p.id == widget.initialPhotoId)
              : 0;

          if (_currentIndex == 0 && initialIndex > 0) {
            _currentIndex = initialIndex;
            _pageController = PageController(initialPage: initialIndex);
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            itemCount: state.allPhotos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final photo = state.allPhotos[index];
              final canDelete = state.isHost || photo.isUploadedByCurrentUser;

              return _buildPhotoPage(
                context,
                photo,
                canDelete,
                state,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Insets.screenH),
            child: Text(
              'Error loading photos: $error',
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

  Widget _buildPhotoPage(
    BuildContext context,
    ManagePhotoItem photo,
    bool canDelete,
    ManageMemoryState state,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate photo dimensions respecting aspect ratio and screen bounds
    // Leave space for header info (~80px) and promote button (~80px)
    final availableHeight = screenHeight - 160;
    final availableWidth = screenWidth - (Insets.screenH * 2);

    double photoWidth;
    double photoHeight;

    if (photo.isPortrait) {
      // Portrait: 4:5 aspect ratio
      final aspectRatio = 4 / 5;
      photoHeight = availableHeight;
      photoWidth = photoHeight * aspectRatio;

      // Ensure width fits
      if (photoWidth > availableWidth) {
        photoWidth = availableWidth;
        photoHeight = photoWidth / aspectRatio;
      }
    } else {
      // Landscape: 16:9 aspect ratio
      final aspectRatio = 16 / 9;
      photoWidth = availableWidth;
      photoHeight = photoWidth / aspectRatio;

      // Ensure height fits
      if (photoHeight > availableHeight) {
        photoHeight = availableHeight;
        photoWidth = photoHeight * aspectRatio;
      }
    }

    return Column(
      children: [
        // Top info section (reduced spacing)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.screenH,
            Gaps.sm,
            Insets.screenH,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Uploader info with profile photo
              Row(
                children: [
                  // Profile photo
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BrandColors.bg3,
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://i.pravatar.cc/150?u=${photo.uploaderId}',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: Gaps.sm),
                  // Uploader name
                  Text(
                    photo.isUploadedByCurrentUser ? 'You' : photo.uploaderName,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                ],
              ),

              // Delete button (only if can delete)
              if (canDelete)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: BrandColors.text2,
                    size: 24,
                  ),
                  onPressed: () => _handleDeletePhoto(context, photo, state),
                ),
            ],
          ),
        ),

        // Photo (centered)
        Expanded(
          child: Center(
            child: Container(
              width: photoWidth,
              height: photoHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.md),
                color: BrandColors.bg2,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: Image.network(
                  photo.thumbnailUrl ?? photo.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: BrandColors.text2,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // Bottom section - Promote to Cover button (recap color)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.screenH,
            Gaps.sm,
            Insets.screenH,
            Insets.screenH
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handlePromoteToCover(context, photo),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.bg2,
                padding: const EdgeInsets.symmetric(vertical: Pads.ctlVSm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.smAlt),
                ),
              ),
              child: Text(
                'Promote to Cover',
                style: AppText.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDeletePhoto(
    BuildContext context,
    ManagePhotoItem photo,
    ManageMemoryState state,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Photo',
        message: 'Are you sure you want to delete this photo?',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: () {},
      ),
    );

    if (confirmed == true || confirmed == null) {
      // Note: confirmation dialog closes automatically, so we check for both true and null
      if (!mounted) return;

      // Remove photo via provider
      await ref
          .read(manageMemoryProvider(widget.memoryId).notifier)
          .removePhoto(photo.id);

      // If this was the last photo or if we need to go back
      if (!mounted) return;

      final updatedState = ref.read(manageMemoryProvider(widget.memoryId));
      updatedState.whenData((data) {
        if (data.allPhotos.isEmpty) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else if (_currentIndex >= data.allPhotos.length) {
          // Adjust current index if we deleted the last photo
          setState(() {
            _currentIndex = data.allPhotos.length - 1;
          });
        }
      });
    }
  }

  void _handlePromoteToCover(BuildContext context, ManagePhotoItem photo) {
    // Promote to cover
    ref.read(manageMemoryProvider(widget.memoryId).notifier).selectCover(photo);

    // Navigate back to Manage Photos
    Navigator.of(context).pop();

    // Show success banner on Manage Photos page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        TopBanner.showSuccess(
          context,
          message: 'Photo promoted to cover',
        );
      }
    });
  }
}
