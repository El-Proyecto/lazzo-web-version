import 'package:flutter/material.dart';
import '../../../../../styles/app_styles.dart';

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
          const SizedBox(
            width: 355,
            child: Text(
              'Enter verification code',
              style: AppTextStyles.enterCodeTitle,
            ),
          ),
          const SizedBox(height: 16),
          // subtitle with phone
          SizedBox(
            width: 355,
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'We sent a verification code to ',
                    style: AppTextStyles.subtitleMuted,
                  ),
                  TextSpan(text: email, style: AppTextStyles.subtitleStrong),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
