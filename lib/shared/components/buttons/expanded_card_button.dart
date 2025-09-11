import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../themes/colors.dart';

class ExpandedCardButton extends StatelessWidget {
  final VoidCallback? onTap;

  const ExpandedCardButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: ShapeDecoration(
          color: BrandColors.bg3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
        child: const Icon(
          Icons.edit_outlined,
          size: 18,
          color: BrandColors.text1,
        ),
      ),
    );
  }
}
