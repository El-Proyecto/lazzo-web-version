import 'package:flutter/material.dart';
import '../../../../../shared/constants/text_styles.dart';
import '../../../../../shared/themes/colors.dart';

class OtpTitle extends StatelessWidget {
  const OtpTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Check your email',
      style: AppText.headlineMedium.copyWith(
        color: BrandColors.text1,
      ),
    );
  }
}
