import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/text_styles.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: BrandColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Gaps.md),
          child: Text(
            'OR',
            style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
          ),
        ),
        Expanded(child: Container(height: 1, color: BrandColors.border)),
      ],
    );
  }
}
