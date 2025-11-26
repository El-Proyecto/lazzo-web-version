import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Card for adding photos to memory
/// Shows camera icon for living state, add icon for recap state
class AddPhotoCard extends StatelessWidget {
  final double width;
  final double height;
  final bool isLiving;
  final VoidCallback onTap;

  const AddPhotoCard({
    super.key,
    required this.width,
    required this.height,
    required this.isLiving,
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
          border: Border.all(color: BrandColors.border, width: 1),
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLiving
                  ? Icons.camera_alt_outlined
                  : Icons.add_photo_alternate_outlined,
              color: BrandColors.text2,
              size: 32,
            ),
            const SizedBox(height: Gaps.xs),
            Text(
              isLiving ? 'Take Photo' : 'Add Photo',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
