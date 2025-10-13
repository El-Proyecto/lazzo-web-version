import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Enhanced photo selector for groups with separate camera and gallery callbacks
class GroupPhotoSelectorWithCamera extends StatelessWidget {
  final String? photoUrl;
  final VoidCallback? onGallerySelected;
  final VoidCallback? onCameraSelected;
  final VoidCallback? onPhotoRemoved;
  final String addPhotoText;
  final double size;
  final bool showRemoveOption;

  const GroupPhotoSelectorWithCamera({
    super.key,
    this.photoUrl,
    this.onGallerySelected,
    this.onCameraSelected,
    this.onPhotoRemoved,
    this.addPhotoText = 'Add Photo',
    this.size = 120,
    this.showRemoveOption = true,
  });

  void _showPhotoSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BrandColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
      ),
      builder: (context) => _PhotoSelectionBottomSheet(
        showRemoveOption: showRemoveOption && photoUrl != null,
        onGallery: () {
          Navigator.pop(context);
          onGallerySelected?.call();
        },
        onCamera: () {
          Navigator.pop(context);
          onCameraSelected?.call();
        },
        onRemove: () {
          Navigator.pop(context);
          onPhotoRemoved?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Column(
      children: [
        // Photo container
        GestureDetector(
          onTap: () => _showPhotoSelectionBottomSheet(context),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: BrandColors.bg2,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: hasPhoto
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.md),
                    child: _buildPhotoImage(photoUrl!),
                  )
                : const _PhotoPlaceholder(),
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

  /// Helper method to build photo image based on URL or local path
  Widget _buildPhotoImage(String photoPath) {
    // Check if it's a URL or local file path
    if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
      // Network image
      return Image.network(
        photoPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const _PhotoPlaceholder();
        },
      );
    } else {
      // Local file
      return Image.file(
        File(photoPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const _PhotoPlaceholder();
        },
      );
    }
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
        size: 48,
        color: BrandColors.text2,
      ),
    );
  }
}

/// Bottom sheet for photo selection with specific callbacks
class _PhotoSelectionBottomSheet extends StatelessWidget {
  final bool showRemoveOption;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onRemove;

  const _PhotoSelectionBottomSheet({
    required this.showRemoveOption,
    required this.onGallery,
    required this.onCamera,
    required this.onRemove,
  });

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
            onTap: onGallery,
          ),

          const SizedBox(height: Gaps.md),

          // Camera option
          _PhotoOption(
            icon: Icons.camera_alt_outlined,
            title: 'Take Photo',
            onTap: onCamera,
          ),

          // Remove option (conditional)
          if (showRemoveOption) ...[
            const SizedBox(height: Gaps.md),
            _PhotoOption(
              icon: Icons.delete_outline,
              title: 'Remove Photo',
              onTap: onRemove,
              isDestructive: true,
            ),
          ],

          const SizedBox(height: Gaps.lg),
        ],
      ),
    );
  }
}

/// Individual photo option widget
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.screenH,
          vertical: Gaps.md,
        ),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : BrandColors.text1,
              size: IconSizes.md,
            ),
            const SizedBox(width: Gaps.md),
            Text(
              title,
              style: AppText.bodyMedium.copyWith(
                color: isDestructive ? Colors.red : BrandColors.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}