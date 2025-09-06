import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../themes/colors.dart';

class ExpandedCardButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const ExpandedCardButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: ShapeDecoration(
          color: BrandColors.bg3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
        child: Icon(icon, size: 20, color: BrandColors.text1),
      ),
    );
  }
}
