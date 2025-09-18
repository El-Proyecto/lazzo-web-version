import 'package:flutter/material.dart';
import '../../../shared/constants/spacing.dart';
import '../../../shared/themes/colors.dart';
import '../../../shared/constants/text_styles.dart';

class InputBox extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;

  const InputBox({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.labelLarge),
        SizedBox(height: Gaps.xs),
        Container(
          width: double.infinity,
          height: 48,
          decoration: ShapeDecoration(
            color: BrandColors.bg2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              contentPadding: EdgeInsets.all(Insets.screenH),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}