import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Card for adding photos in the memory grid — matches web `AddPhotoCard`:
/// gray border, bg2, plus icon, “Add” (no purple/orange on the tile).
class AddPhotoCard extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onTap;

  const AddPhotoCard({
    super.key,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: BrandColors.border, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: IconSizes.md,
              color: BrandColors.text2,
            ),
            const SizedBox(height: Gaps.xxs),
            Text(
              'Add',
              style: AppText.labelLarge.copyWith(
                color: BrandColors.text2,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
