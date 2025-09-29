import 'package:flutter/material.dart';
import '../../../shared/constants/spacing.dart';
import '../../../shared/constants/text_styles.dart';
import '../../../shared/themes/colors.dart';

/// Enum for photo source selection
enum PhotoSourceAction { gallery, camera, remove }

/// Shared component for photo selection with edit overlay
/// Combines functionality from EditableProfilePhoto and PhotoChangeBottomSheet
class PhotoSelector extends StatelessWidget {
  final String? photoUrl;
  final VoidCallback? onPhotoSelected;
  final VoidCallback? onPhotoRemoved;
  final String addPhotoText;
  final double size;
  final bool showEditOverlay;
  final bool showRemoveOption;

  const PhotoSelector({
    super.key,
    this.photoUrl,
    this.onPhotoSelected,
    this.onPhotoRemoved,
    this.addPhotoText = 'Add Photo',
    this.size = 120,
    this.showEditOverlay = true,
    this.showRemoveOption = true,
  });

  void _showPhotoSelectionBottomSheet(BuildContext context) {
    PhotoSelectionBottomSheet.show(
      context: context,
      showRemoveOption: showRemoveOption && photoUrl != null,
      onAction: (action) {
        switch (action) {
          case PhotoSourceAction.gallery:
          case PhotoSourceAction.camera:
            onPhotoSelected?.call();
            break;
          case PhotoSourceAction.remove:
            onPhotoRemoved?.call();
            break;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _showPhotoSelectionBottomSheet(context),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: BrandColors.bg2,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo or placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: hasPhoto
                      ? Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const _PhotoPlaceholder();
                          },
                        )
                      : const _PhotoPlaceholder(),
                ),

                // Edit overlay (only show when there's a photo and showEditOverlay is true)
                if (hasPhoto && showEditOverlay)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: Gaps.xs),
                      decoration: BoxDecoration(
                        color: BrandColors.bg1.withValues(alpha: 0.8),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(Radii.md),
                          bottomRight: Radius.circular(Radii.md),
                        ),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: BrandColors.text1,
                        size: IconSizes.sm,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Photo text label (always show)
        const SizedBox(height: Gaps.xs),
        GestureDetector(
          onTap: () => _showPhotoSelectionBottomSheet(context),
          child: Text(
            hasPhoto ? 'Change Photo' : addPhotoText,
            style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
          ),
        ),
      ],
    );
  }
}

/// Placeholder widget for when no photo is selected
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.add_a_photo_outlined,
        size: IconSizes.lg,
        color: BrandColors.text2,
      ),
    );
  }
}

/// Bottom sheet for photo selection options
class PhotoSelectionBottomSheet extends StatelessWidget {
  final bool showRemoveOption;
  final Function(PhotoSourceAction) onAction;

  const PhotoSelectionBottomSheet({
    super.key,
    required this.showRemoveOption,
    required this.onAction,
  });

  static Future<void> show({
    required BuildContext context,
    required bool showRemoveOption,
    required Function(PhotoSourceAction) onAction,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        width: double.infinity,
        decoration: const ShapeDecoration(
          color: BrandColors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Radii.pill),
              topRight: Radius.circular(Radii.pill),
            ),
          ),
        ),
        child: SafeArea(
          child: PhotoSelectionBottomSheet(
            showRemoveOption: showRemoveOption,
            onAction: (action) {
              Navigator.of(context).pop();
              onAction(action);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Insets.screenH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Change Photo',
            style: AppText.labelLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: Gaps.lg),

          // Gallery option
          _PhotoOption(
            icon: Icons.photo_library_outlined,
            title: 'Choose from Gallery',
            onTap: () => onAction(PhotoSourceAction.gallery),
          ),

          const SizedBox(height: Gaps.md),

          // Camera option
          _PhotoOption(
            icon: Icons.camera_alt_outlined,
            title: 'Take Photo',
            onTap: () => onAction(PhotoSourceAction.camera),
          ),

          // Remove option (conditional)
          if (showRemoveOption) ...[
            const SizedBox(height: Gaps.md),
            _PhotoOption(
              icon: Icons.delete_outline,
              title: 'Remove Photo',
              onTap: () => onAction(PhotoSourceAction.remove),
              isDestructive: true,
            ),
          ],

          const SizedBox(height: Gaps.lg),
        ],
      ),
    );
  }
}

/// Individual photo option in the bottom sheet
class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _PhotoOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Pads.ctlV),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? BrandColors.cantVote : BrandColors.text1,
              size: IconSizes.md,
            ),
            const SizedBox(width: Gaps.sm),
            Text(
              title,
              style: AppText.bodyMedium.copyWith(
                color: isDestructive ? BrandColors.cantVote : BrandColors.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
