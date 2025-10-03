import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Widget for selecting group photo
class GroupPhotoSelector extends StatelessWidget {
  final String? photoUrl;
  final VoidCallback onTap;

  const GroupPhotoSelector({super.key, this.photoUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 120,
            height: 120,
            decoration: const ShapeDecoration(
              color: BrandColors.bg2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(Radii.md)),
              ),
            ),
            child: photoUrl != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(Radii.md),
                    ),
                    child: Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const _PhotoPlaceholder();
                      },
                    ),
                  )
                : const _PhotoPlaceholder(),
          ),
        ),
        const SizedBox(height: Gaps.xs),
        Text(
          'Add Photo',
          style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
        ),
      ],
    );
  }
}

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
