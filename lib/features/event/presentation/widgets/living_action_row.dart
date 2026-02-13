import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Action row for living mode with action buttons:
/// Take Photo (purple), View Memory
class LivingActionRow extends StatelessWidget {
  final VoidCallback onTakePhoto;
  final VoidCallback onViewMemory;

  const LivingActionRow({
    super.key,
    required this.onTakePhoto,
    required this.onViewMemory,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.camera_alt,
            label: 'Photo',
            onPressed: onTakePhoto,
            backgroundColor: BrandColors.living,
            textColor: Colors.white,
            iconColor: Colors.white,
          ),
        ),
        const SizedBox(width: Gaps.sm),
        Expanded(
          child: _ActionButton(
            icon: Icons.photo_library,
            label: 'Memory',
            onPressed: onViewMemory,
            backgroundColor: BrandColors.bg2,
            textColor: BrandColors.text1,
            iconColor: BrandColors.text1,
          ),
        ),
      ],
    );
  }
}

/// Individual action button with large icon and label below
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: Pads.sectionH,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: iconColor,
            ),
            const SizedBox(height: Gaps.xxs),
            Text(
              label,
              style: AppText.labelLarge.copyWith(
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
