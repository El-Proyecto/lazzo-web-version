import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../shared/constants/spacing.dart';
import '../../../shared/themes/colors.dart';
import '../../../shared/constants/text_styles.dart';

class ContinueWith extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;

  const ContinueWith({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: BrandColors.bg3,
          padding: EdgeInsets.all(Insets.screenH),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 20,
                color: BrandColors.text1,
              ),
              SizedBox(width: Gaps.xs),
              Text(
                text,
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}