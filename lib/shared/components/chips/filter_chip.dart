import 'package:flutter/material.dart';
import '../../../shared/constants/spacing.dart';
import '../../../shared/constants/text_styles.dart';
import '../../../shared/themes/colors.dart';

class CustomFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: 6.0, // Reduzido para menor espaçamento vertical
        ),
        decoration: BoxDecoration(
          color: isSelected ? BrandColors.planning : BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(
            color: isSelected ? BrandColors.planning : BrandColors.bg3,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppText.labelLarge.copyWith(
            color: isSelected ? BrandColors.bg1 : BrandColors.text2,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
