import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';

/// Button shown when user voted "no" but still wants to see results
class VotedNoButton extends StatelessWidget {
  final VoidCallback? onTap;

  const VotedNoButton({super.key, this.onTap});

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
        child: const Icon(
          Icons.expand_more,
          size: 20,
          color: BrandColors.text1,
        ),
      ),
    );
  }
}
