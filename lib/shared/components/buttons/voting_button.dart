import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../themes/colors.dart';

/// Vote button in the "Voting" state - showing Yes/No options
class VotingButton extends StatelessWidget {
  final VoidCallback? onYes;
  final VoidCallback? onNo;

  const VotingButton({super.key, this.onYes, this.onNo});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // No button (Red)
        GestureDetector(
          onTap: onNo,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: ShapeDecoration(
              color: const Color(0x33D25440), // Red with opacity
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: Color(0xFFB93E2B), // Red border
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: SizedBox(
              width: 20,
              height: 20,
              child: Icon(Icons.close, size: 16, color: Color(0xFFB93E2B)),
            ),
          ),
        ),
        const SizedBox(width: Gaps.xs),

        // Yes button (Green)
        GestureDetector(
          onTap: onYes,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: ShapeDecoration(
              color: BrandColors.planning.withValues(alpha: 0.2), // Green with opacity
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  width: 1,
                  color: BrandColors.planning, // Green border
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: Icon(Icons.check, size: 16, color: BrandColors.planning),
            ),
          ),
        ),
      ],
    );
  }
}
