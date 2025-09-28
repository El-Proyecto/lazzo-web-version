import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

enum PhotoSourceAction { gallery, camera, remove }

/// Tokenized bottom sheet for photo change options
/// Shows gallery, camera, and remove options with proper spacing
class PhotoChangeBottomSheet extends StatelessWidget {
  final bool hasCurrentPhoto;
  final Function(PhotoSourceAction) onAction;

  const PhotoChangeBottomSheet({
    super.key,
    required this.hasCurrentPhoto,
    required this.onAction,
  });

  static Future<void> show({
    required BuildContext context,
    required bool hasCurrentPhoto,
    required Function(PhotoSourceAction) onAction,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PhotoChangeBottomSheet(
        hasCurrentPhoto: hasCurrentPhoto,
        onAction: onAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: Padding(
          padding: const EdgeInsets.all(Pads.sectionH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 32,
                height: 4,
                decoration: ShapeDecoration(
                  color: BrandColors.text2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: Gaps.lg),

              // Title
              Text(
                'Change Photo',
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
              ),

              const SizedBox(height: Gaps.lg),

              // Options
              _buildOption(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Gallery',
                onTap: () => _handleAction(context, PhotoSourceAction.gallery),
              ),

              const SizedBox(height: Gaps.sm),

              _buildOption(
                icon: Icons.camera_alt_outlined,
                title: 'Take Photo',
                onTap: () => _handleAction(context, PhotoSourceAction.camera),
              ),

              if (hasCurrentPhoto) ...[
                const SizedBox(height: Gaps.sm),
                _buildOption(
                  icon: Icons.delete_outline,
                  title: 'Remove Photo',
                  isDestructive: true,
                  onTap: () => _handleAction(context, PhotoSourceAction.remove),
                ),
              ],

              const SizedBox(height: Gaps.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Pads.ctlH),
        decoration: ShapeDecoration(
          color: BrandColors.bg3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDestructive ? BrandColors.cantVote : BrandColors.text2,
            ),

            const SizedBox(width: Gaps.md),

            Text(
              title,
              style: AppText.bodyMediumEmph.copyWith(
                color: isDestructive ? BrandColors.cantVote : BrandColors.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, PhotoSourceAction action) {
    Navigator.of(context).pop();
    onAction(action);
  }
}
