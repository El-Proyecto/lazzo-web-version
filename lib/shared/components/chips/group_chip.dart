import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Chip para exibir grupo com avatar e nome, com estado selecionado
class GroupChip extends StatelessWidget {
  final String groupName;
  final String? groupPhotoUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const GroupChip({
    super.key,
    required this.groupName,
    this.groupPhotoUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(
          left: Pads.ctlH, // 16
          right: Pads.ctlH, // 16
          top: Pads.ctlVXss, // 6
          bottom: Pads.ctlVXss, // 6
        ),
        decoration: BoxDecoration(
          color: isSelected ? BrandColors.planning : BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.smAlt), // 12
          border: Border.all(
            color: isSelected ? BrandColors.planning : Colors.transparent,
            width: 1.5, // Keep specific value for selected state
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Group name - White text when selected
            Text(
              groupName,
              style: AppText.labelLarge.copyWith(
                color: isSelected ? Colors.white : BrandColors.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
