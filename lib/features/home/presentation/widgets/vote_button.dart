// TODO P2: Remove this file - replaced by new home structure
import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Vote button in the "Vote" state - user hasn't voted yet
class VoteButton extends StatelessWidget {
  final VoidCallback? onTap;

  const VoteButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Radii.sm,
        ),
        decoration: ShapeDecoration(
          color: BrandColors.planning,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
        child: Text(
          'Vote',
          textAlign: TextAlign.center,
          style: AppText.labelLarge.copyWith(color: BrandColors.text1),
        ),
      ),
    );
  }
}
