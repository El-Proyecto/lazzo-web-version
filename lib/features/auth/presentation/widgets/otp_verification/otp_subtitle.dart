import 'package:flutter/material.dart';
import '../../../../../shared/constants/text_styles.dart';
import '../../../../../shared/themes/colors.dart';

class OtpSubtitle extends StatelessWidget {
  final String email;

  const OtpSubtitle({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'We sent a code to ',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
            ),
          ),
          TextSpan(
            text: email,
            style: AppText.bodyMediumEmph.copyWith(
              color: BrandColors.text1,
            ),
          ),
        ],
      ),
    );
  }
}
