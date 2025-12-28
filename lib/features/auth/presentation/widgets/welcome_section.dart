import 'package:flutter/material.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/constants/spacing.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create your account',
          style: AppText.headlineMedium.copyWith(
            fontSize: 24,
            color: BrandColors.text1,
          ),
        ),
        const SizedBox(height: Gaps.xs),
        Text(
          'Add your name and email. No password needed.',
          style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
        ),
      ],
    );
  }
}
