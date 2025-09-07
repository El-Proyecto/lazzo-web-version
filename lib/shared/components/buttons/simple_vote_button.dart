import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../themes/colors.dart';

class SimpleVoteButton extends StatelessWidget {
  final VoidCallback? onTap;

  const SimpleVoteButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: ShapeDecoration(
          color: BrandColors.planning,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
        child: const Icon(
          Icons.how_to_vote_outlined,
          size: 20,
          color: BrandColors.text1,
        ),
      ),
    );
  }
}
