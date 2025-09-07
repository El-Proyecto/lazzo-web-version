import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

class SimpleVoteButton extends StatelessWidget {
  final VoidCallback? onTap;

  const SimpleVoteButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: ShapeDecoration(
          color: BrandColors.planning,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
        child: Center(
          child: Text(
            'Vote',
            style: AppText.bodyMediumEmph.copyWith(color: BrandColors.text1),
          ),
        ),
      ),
    );
  }
}
