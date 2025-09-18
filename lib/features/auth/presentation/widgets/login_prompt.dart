import 'package:flutter/material.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/text_styles.dart';

class LoginPrompt extends StatelessWidget {
  final String text;
  final String actionText;
  final VoidCallback? onTap;

  const LoginPrompt({
    super.key,
    this.text = 'Already have an account? ',
    this.actionText = 'Log In',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: AppText.bodyMediumEmph.copyWith(color: BrandColors.text1),
          ),
        ),
      ],
    );
  }
}
