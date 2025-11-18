import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// CTA card prompting users to add photos to a memory
/// Used in Living and Recap states
/// Layout: Title/subtitle on left, icon button on right
///
/// P1 Implementation Notes:
/// - Currently navigates to Manage Photos for testing/preview
/// - P2 TODO: Replace with actual camera/gallery picker:
///   * Living state: open camera directly (Icons.camera_alt)
///   * Recap state: open photo gallery picker (Icons.add_photo_alternate)
class AddPhotosCtaCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color buttonColor;
  final VoidCallback onPressed;

  const AddPhotosCtaCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.buttonColor,
    required this.onPressed,
  });

  /// Factory for Living state
  /// P2 TODO: onPressed should open camera directly
  factory AddPhotosCtaCard.living({
    required VoidCallback onPressed,
  }) {
    return AddPhotosCtaCard(
      title: 'Add your photos',
      subtitle: 'You can then select a photo cover',
      icon: Icons.camera_alt,
      buttonColor: BrandColors.living, // Purple
      onPressed: onPressed,
    );
  }

  /// Factory for Recap state
  /// P2 TODO: onPressed should open photo gallery picker
  factory AddPhotosCtaCard.recap({
    required VoidCallback onPressed,
  }) {
    return AddPhotosCtaCard(
      title: 'Add your photos',
      subtitle: 'You can then select a photo cover',
      icon: Icons.add_photo_alternate,
      buttonColor: BrandColors.recap, // Orange
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gaps.md),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          // Text content (left)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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

          // Icon button (right)
          GestureDetector(
            onTap: onPressed,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(Radii.smAlt),
              ),
              child: Icon(
                icon,
                color: BrandColors.text1,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
