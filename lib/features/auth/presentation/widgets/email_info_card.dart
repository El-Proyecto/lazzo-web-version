import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Non-editable email info card for profile information
/// Shows email in view-only mode with same format as other cards
class EmailInfoCard extends StatelessWidget {
  final String? email;

  const EmailInfoCard({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    final hasValue = email != null && email!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.ctlH,
        vertical: Pads.ctlV,
      ),
      decoration: ShapeDecoration(
        color: hasValue ? BrandColors.bg2 : BrandColors.bg3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Label
          Text(
            'Email',
            style: AppText.bodyMediumEmph.copyWith(
              color: BrandColors.text1,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Right side: Email value
          Text(
            hasValue ? email! : 'Not provided',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
