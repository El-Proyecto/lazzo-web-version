import 'package:flutter/material.dart';
import '../../../../../shared/themes/colors.dart';
import '../../../../../shared/constants/text_styles.dart';

class EnterCodeTitle extends StatelessWidget {
  const EnterCodeTitle({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          SizedBox(
            width: 355,
            child: Text(
              'Enter verification code',
              style: AppText.enterCodeTitle.copyWith(color: BrandColors.text1),
            ),
          ),
          const SizedBox(height: 16),
          // subtitle with phone
          SizedBox(
            width: 355,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'We sent a verification code to ',
                    style: AppText.subtitleMuted.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                  TextSpan(
                    text: email,
                    style: AppText.subtitleStrong.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
