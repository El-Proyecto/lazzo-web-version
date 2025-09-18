import 'package:flutter/material.dart';
import '../../themes/colors.dart';
import '../../constants/text_styles.dart';

class LazzoHeader extends StatelessWidget {
  const LazzoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'LAZZO',
      textAlign: TextAlign.center,
      style: AppText.headlineMedium.copyWith(
        color: BrandColors.text1,
        fontStyle: FontStyle.italic,
        fontFamily: 'Public Sans',
        letterSpacing: 2,
      ),
    );
  }
}
